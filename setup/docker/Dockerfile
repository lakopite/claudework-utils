FROM node:22-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    tmux \
    git \
    openssh-client \
    xxd \
    jq \
    python3 \
    uuid-runtime \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g @anthropic-ai/claude-code

RUN useradd -m -s /bin/bash -u 1000 claude

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER claude
WORKDIR /home/claude

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
