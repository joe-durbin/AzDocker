# Dockerfile - Microsoft Cloud Attack & Defense tools box (non-root 'pentest')
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    PIPX_HOME=/opt/pipx \
    PIPX_BIN_DIR=/opt/pipx/bin \
    INSTALL_DIR=/opt/pentest-azure \
    PATH=/opt/pipx/bin:$PATH

# Base packages, Python, Ruby, "pretty" tools, and bash completion
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    unzip \
    ca-certificates \
    gnupg \
    software-properties-common \
    python3 \
    python3-pip \
    python3-venv \
    pipx \
    jq \
    libxml2-utils \
    hashcat \
    ruby-full \
    build-essential \
    zlib1g-dev \
    libssl-dev \
    libreadline-dev \
    pkg-config \
    bash-completion \
    bat \
    eza \
    nano \
    vim \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# System-wide pipx location
RUN mkdir -p "${PIPX_HOME}" "${PIPX_BIN_DIR}" && pipx ensurepath

# On Ubuntu the binary is "batcat" – add a "bat" shim for convenience
RUN ln -s /usr/bin/batcat /usr/local/bin/bat

# Install PowerShell from Microsoft repo (Ubuntu 24.04 / noble)
RUN curl -sSL -o /tmp/packages-microsoft-prod.deb \
      https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb && \
    dpkg -i /tmp/packages-microsoft-prod.deb && \
    rm /tmp/packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y powershell && \
    rm -rf /var/lib/apt/lists/*

# Install jwt-cli from GitHub releases
RUN JWT_CLI_VERSION=$(curl -s https://api.github.com/repos/mike-engel/jwt-cli/releases/latest | jq -r '.tag_name') && \
    curl -sSL -o /tmp/jwt-cli.tar.gz \
      "https://github.com/mike-engel/jwt-cli/releases/download/${JWT_CLI_VERSION}/jwt-cli-${JWT_CLI_VERSION}-x86_64-unknown-linux-gnu.tar.gz" && \
    tar -xzf /tmp/jwt-cli.tar.gz -C /tmp && \
    mv /tmp/jwt /usr/bin/jwt && \
    chmod +x /usr/bin/jwt && \
    rm -f /tmp/jwt-cli.tar.gz

# Install Azure and cloud security tools via pipx
# azure-cli, graphspy, ROADtools, FindMeAccess, impacket, seamlesspass, roadtx, prowler, scoutsuite
RUN pipx install azure-cli && \
    pipx install graphspy && \
    pipx install "git+https://github.com/dirkjanm/ROADtools" --include-deps && \
    pipx install "git+https://github.com/absolomb/FindMeAccess" --include-deps && \
    pipx install impacket && \
    pipx install seamlesspass && \
    pipx install roadtx && \
    pipx install prowler && \
    pipx install scoutsuite

# Enable bash completion for az CLI
RUN az completion bash > /etc/bash_completion.d/azure-cli || true

# Clone offensive security and enumeration tools repositories
RUN mkdir -p "$INSTALL_DIR"
WORKDIR $INSTALL_DIR

RUN git clone https://github.com/Gerenios/AADInternals "$INSTALL_DIR/AADInternals" && \
    git clone https://github.com/dafthack/GraphRunner "$INSTALL_DIR/GraphRunner" && \
    git clone https://github.com/f-bader/TokenTacticsV2 "$INSTALL_DIR/TokenTacticsV2" && \
    git clone https://github.com/dafthack/MFASweep "$INSTALL_DIR/MFASweep" && \
    git clone https://github.com/urbanadventurer/username-anarchy "$INSTALL_DIR/username-anarchy" && \
    git clone https://github.com/yuyudhn/AzSubEnum "$INSTALL_DIR/AzSubEnum" && \
    git clone https://github.com/joswr1ght/basicblobfinder "$INSTALL_DIR/basicblobfinder" && \
    git clone https://github.com/gremwell/o365enum "$INSTALL_DIR/o365enum" && \
    git clone https://github.com/0xZDH/o365spray "$INSTALL_DIR/o365spray" && \
    git clone https://github.com/0xZDH/Omnispray "$INSTALL_DIR/Omnispray" && \
    git clone https://github.com/dievus/Oh365UserFinder "$INSTALL_DIR/Oh365UserFinder" && \
    git clone https://github.com/dafthack/MSOLSpray "$INSTALL_DIR/MSOLSpray" && \
    git clone https://github.com/mlcsec/Graphpython "$INSTALL_DIR/Graphpython" && \
    git clone https://github.com/hac01/uwg "$INSTALL_DIR/uwg"

# Install Graphpython into the system Python
# Note: --break-system-packages is required for Ubuntu 24.04 (PEP 668)
RUN pip install --no-cache-dir --break-system-packages "$INSTALL_DIR/Graphpython"

# Optional: install Python requirements for tools that ship them
RUN if [ -f "$INSTALL_DIR/TokenTacticsV2/requirements.txt" ]; then \
        pip install --no-cache-dir --break-system-packages -r "$INSTALL_DIR/TokenTacticsV2/requirements.txt"; \
    fi && \
    if [ -f "$INSTALL_DIR/MFASweep/requirements.txt" ]; then \
        pip install --no-cache-dir --break-system-packages -r "$INSTALL_DIR/MFASweep/requirements.txt"; \
    fi

# Download Exchange mail exfiltration script (best-effort download)
RUN mkdir -p "$INSTALL_DIR/exfil_exchange_mail" && \
    wget -O "$INSTALL_DIR/exfil_exchange_mail/exfil_exchange_mail.py" \
      "https://raw.githubusercontent.com/rootsecdev/Azure-Red-Team/master/exfil_exchange_mail.py" || true

# Install evil-winrm Ruby gem for Windows Remote Management
RUN gem install evil-winrm

# Install PowerShell modules for Azure and Microsoft Graph management
RUN pwsh -NoLogo -NoProfile -Command \
    "Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted; \
     Install-Module -Name AADInternals    -Force -Scope AllUsers; \
     Install-Module -Name Microsoft.Graph -Force -Scope AllUsers; \
     Install-Module -Name Az              -Force -Scope AllUsers"

# ----- Create non-root user 'pentest' -----
RUN useradd -m -s /bin/bash pentest

# Configure passwordless sudo for pentest user
RUN echo "pentest ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/pentest && \
    chmod 0440 /etc/sudoers.d/pentest

# PowerShell modules are installed but not auto-loaded to improve startup time
# Import modules manually when needed: Import-Module Az, Import-Module Microsoft.Graph, Import-Module AADInternals

# Install Starship prompt and configure for 'pentest' user
RUN curl -sS https://starship.rs/install.sh | sh -s -- -y

# Copy starship.toml from build context into pentest's config
# (Place starship.toml in config_files/ directory next to this Dockerfile)
RUN mkdir -p /home/pentest/.config
COPY config_files/starship.toml /home/pentest/.config/starship.toml

# Bash RC for 'pentest': bash-completion, Starship, and aliases
RUN printf '\n# Enable bash completion (including az from /etc/bash_completion.d)\n' >> /home/pentest/.bashrc && \
    printf 'if [ -f /etc/bash_completion ]; then\n' >> /home/pentest/.bashrc && \
    printf '    . /etc/bash_completion\n' >> /home/pentest/.bashrc && \
    printf 'fi\n\n' >> /home/pentest/.bashrc && \
    printf '# Initialize Starship prompt for Bash\n' >> /home/pentest/.bashrc && \
    printf 'eval "$(starship init bash)"\n\n' >> /home/pentest/.bashrc && \
    printf '# Aliases for enhanced usability\n' >> /home/pentest/.bashrc && \
    printf 'alias cat="bat -p"        # Pretty cat using bat\n' >> /home/pentest/.bashrc && \
    printf 'alias ls="eza --icons"    # Enhanced ls with icons\n' >> /home/pentest/.bashrc

# Make sure pentest owns its home, tools dir, and pipx dir
RUN chown -R pentest:pentest /home/pentest "$INSTALL_DIR" "$PIPX_HOME"

# Switch to non-root user
USER pentest
WORKDIR /home/pentest

CMD ["/bin/bash"]
