# Dockerfile for a web‑accessible OpenCode AI Lab
# -------------------------------------------------
# This image builds a minimal Ubuntu environment, installs the
# required system packages, pulls the MiniMax‑M2.7 model, builds
# llama.cpp, installs OpenCode, and finally runs OpenCode behind
# a lightweight web‑terminal (ttyd).  The result is a single URL
# that any browser can open and start interacting with the AI.

FROM ubuntu:22.04

# ---- Install system dependencies ------------------------------------------------
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        build-essential git curl wget python3-pip tmux \
        ca-certificates gnupg lsb-release \
        libssl-dev libncurses5-dev libncursesw5-dev \
        # ttyd (web terminal) dependencies
        libjson-c-dev libwebsockets-dev && \
    rm -rf /var/lib/apt/lists/*

# ---- Install ttyd (web terminal) ------------------------------------------------
# ttyd is a tiny Go program that exposes any CLI as a web terminal.
RUN wget -qO- https://github.com/tsl0922/ttyd/releases/download/1.7.3/ttyd.x86_64.tar.gz | tar xz -C /usr/local/bin && \
    chmod +x /usr/local/bin/ttyd

# ---- Install OpenCode -----------------------------------------------------------
RUN curl -fsSL https://opencode.ai/install | bash || true

# ---- Install llama.cpp -----------------------------------------------------------
WORKDIR /opt/llama.cpp
RUN git clone https://github.com/ggerganov/llama.cpp . && \
    make -j$(nproc)

# ---- Download MiniMax‑M2.7 model -------------------------------------------------
WORKDIR /opt/models
RUN mkdir -p MiniMax-M2.7 && \
    curl -L -o MiniMax-M2.7/ggml-model-q4_k_m.gguf \
    https://huggingface.co/unsloth/MiniMax-M2.7-GGUF/resolve/main/MiniMax-M2.7-Q4_K_M.gguf

# ---- Environment variables ------------------------------------------------------
ENV OPENAI_API_BASE=http://127.0.0.1:8080/v1
ENV OPENAI_API_KEY=local

# ---- Start script ---------------------------------------------------------------
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

EXPOSE 8080 7681

# The container will run the start script which launches llama‑server and
# then serves OpenCode via ttyd on port 8080.
CMD ["/usr/local/bin/start.sh"]
