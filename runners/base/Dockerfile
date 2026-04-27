FROM ghcr.io/actions/actions-runner:latest

USER root

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    docker.io \
    sudo \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install Dagger CLI
RUN curl -L https://dl.dagger.io/dagger/install.sh | BIN_DIR=/usr/local/bin sh

# Ensure runner user has sudo access without password (required for some Docker/Dagger operations if needed)
RUN echo "runner ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/runner

# Set up entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER runner

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
