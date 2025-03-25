ARG CODER_VERSION=4.98.2

# Use the base image for code-server
FROM ghcr.io/coder/code-server:$CODER_VERSION-ubuntu

# Define arguments for tool versions
ARG GOLANG_VERSION=1.24.1
ARG HELM_VERSION=3.17.0
ARG KUBECTL_VERSION=1.32.2
ARG TERRAFORM_VERSION=1.11.2
ARG TFLINT_VERSION=0.55.1
ARG POWERSHELL_VERSION=7.5.0

# Install necessary tools for Dockerfile development and rootless Docker
USER root

# Set non-interactive frontend for debconf to avoid tzdata prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install additional tools and dependencies
RUN apt-get update && apt-get install -y \
    software-properties-common \
    bash-completion \
    unzip \
    python3-pip \
    python3-pymysql \
    python3-jmespath \
    python3-passlib \
    python3-hvac \
    python3-psutil \
    python3-venv \
    curl \
    git \
    vim \
    && curl -fsSL https://golang.org/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz | tar -C /usr/local -xz \
    && ln -s /usr/local/go/bin/go /usr/bin/go \
    && curl -fsSL https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz | tar -xz && mv linux-amd64/helm /usr/local/bin/helm \
    && go install github.com/arttor/helmify/cmd/helmify@latest \
    && curl -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && chmod +x kubectl && mv kubectl /usr/local/bin/ \
    && curl -fsSL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o terraform.zip && unzip terraform.zip && mv terraform /usr/local/bin/ && rm terraform.zip \
    && curl -fsSL https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_amd64.zip -o tflint.zip && unzip tflint.zip && mv tflint /usr/local/bin/ && rm tflint.zip \
    && curl -fsSL https://github.com/PowerShell/PowerShell/releases/download/v${POWERSHELL_VERSION}/powershell-${POWERSHELL_VERSION}-linux-x64.tar.gz | tar -xz -C /usr/local/bin/ \
    && chmod +x /usr/local/bin/pwsh \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Python packages
RUN pip3 install --no-cache-dir \
    boto3 \
    requests \
    ansible

RUN curl -sS https://starship.rs/install.sh | sh -s -- --yes

RUN (type -p wget >/dev/null || (sudo apt update && sudo apt-get install wget -y)) \
    && sudo mkdir -p -m 755 /etc/apt/keyrings \
    && out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    && cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && sudo apt update \
    && sudo apt install gh -y

# Switch back to the non-root user
USER coder

# Install recommended VS Code extensions for Dockerfile development
RUN    code-server --install-extension ms-azuretools.vscode-docker \
    && code-server --install-extension ms-python.python \
    && code-server --install-extension redhat.vscode-yaml \
    && code-server --install-extension golang.go \
    && code-server --install-extension ms-kubernetes-tools.vscode-kubernetes-tools \
    && code-server --install-extension hashicorp.terraform \
    && code-server --install-extension ms-vscode.powershell
