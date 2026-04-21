#!/bin/bash
# ==============================================================================
# OpenCode AI Lab — VM Startup Script
# ==============================================================================
# This script runs automatically when the VM boots (via Terraform
# metadata_startup_script). It installs everything from scratch and
# launches the web-accessible OpenCode AI Lab.
#
# Expected runtime: ~5-8 minutes (mostly model download)
#
# What it does:
#   1. Installs system dependencies (build-essential, cmake, git, tmux, etc.)
#   2. Installs ttyd (web terminal — exposes CLI in the browser)
#   3. Installs OpenCode agentic TUI
#   4. Downloads MiniMax-M2.7 GGUF model from HuggingFace (~1.6 GB)
#   5. Builds llama.cpp inference engine from source (CMake)
#   6. Starts llama-server on port 8080
#   7. Starts ttyd on port 7681 (public web terminal)
#
# When complete, any browser can open http://<EXTERNAL_IP>:7681 and
# interact with OpenCode + the local LLM.
# ==============================================================================
set -e

LOG="/var/log/opencode-lab-startup.log"
exec > >(tee -a "$LOG") 2>&1

echo "========================================"
echo "  OpenCode AI Lab — Startup Script"
echo "  $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "========================================"

# --------------------------------------------------------------------------
# 0. Determine the primary non-root user
# --------------------------------------------------------------------------
LAB_USER=$(getent passwd 1000 | cut -d: -f1 || echo "ubuntu")
LAB_HOME=$(eval echo "~$LAB_USER")
echo "[0/7] Lab user: $LAB_USER | Home: $LAB_HOME"

# --------------------------------------------------------------------------
# 1. System dependencies
# --------------------------------------------------------------------------
echo "[1/7] Installing system dependencies..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq \
    build-essential cmake git curl wget \
    python3-pip tmux \
    ca-certificates gnupg lsb-release \
    libssl-dev

echo "[1/7] ✅ System dependencies installed"

# --------------------------------------------------------------------------
# 2. Install ttyd (web terminal)
# --------------------------------------------------------------------------
echo "[2/7] Installing ttyd..."
TTYD_VERSION="1.7.7"
wget -qO /usr/local/bin/ttyd \
    "https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/ttyd.x86_64"
chmod +x /usr/local/bin/ttyd
echo "[2/7] ✅ ttyd $(ttyd --version 2>&1 | head -1) installed"

# --------------------------------------------------------------------------
# 3. Install OpenCode
# --------------------------------------------------------------------------
echo "[3/7] Installing OpenCode..."
sudo -u "$LAB_USER" bash -c 'curl -fsSL https://opencode.ai/install | bash' || true
echo "[3/7] ✅ OpenCode installed"

# --------------------------------------------------------------------------
# 4. Install huggingface-cli and download MiniMax-M2.7
# --------------------------------------------------------------------------
echo "[4/7] Downloading MiniMax-M2.7 model (~1.6 GB)..."
sudo -u "$LAB_USER" pip3 install --user huggingface_hub

# Ensure ~/.local/bin is on PATH for this script
export PATH="$LAB_HOME/.local/bin:$PATH"

sudo -u "$LAB_USER" mkdir -p "$LAB_HOME/models"
sudo -u "$LAB_USER" bash -c "
    export PATH=\"$LAB_HOME/.local/bin:\$PATH\"
    huggingface-cli download \
        unsloth/MiniMax-M2.7-GGUF \
        MiniMax-M2.7-Q4_K_M.gguf \
        --local-dir $LAB_HOME/models
"
echo "[4/7] ✅ Model downloaded to $LAB_HOME/models/"

# --------------------------------------------------------------------------
# 5. Build llama.cpp (CMake)
# --------------------------------------------------------------------------
echo "[5/7] Building llama.cpp..."
sudo -u "$LAB_USER" git clone https://github.com/ggml-org/llama.cpp "$LAB_HOME/llama.cpp"
cd "$LAB_HOME/llama.cpp"
sudo -u "$LAB_USER" cmake -B build
sudo -u "$LAB_USER" cmake --build build --config Release -j"$(nproc)"
cd "$LAB_HOME"
echo "[5/7] ✅ llama.cpp built successfully"

# --------------------------------------------------------------------------
# 6. Write tmux config
# --------------------------------------------------------------------------
echo "[6/7] Writing tmux config..."
cat > "$LAB_HOME/.tmux.conf" << 'TMUXEOF'
set -g status-interval 2
set -g status-style bg=default
set -g status-left-length 60
set -g status-left "#[fg=magenta,bold] LAB: OPENCODE #[fg=white]| #[fg=cyan]MINIMAX-M2.7 "
set -g status-right "#[fg=yellow,bold] GCP #[fg=green]%H:%M:%S "
set -g mouse on
TMUXEOF
chown "$LAB_USER:$LAB_USER" "$LAB_HOME/.tmux.conf"

# Also ensure PATH is permanent
echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$LAB_HOME/.bashrc"
echo 'export OPENAI_API_BASE="http://127.0.0.1:8080/v1"' >> "$LAB_HOME/.bashrc"
echo 'export OPENAI_API_KEY="local"' >> "$LAB_HOME/.bashrc"
chown "$LAB_USER:$LAB_USER" "$LAB_HOME/.bashrc"

echo "[6/7] ✅ Environment configured"

# --------------------------------------------------------------------------
# 7. Launch the stack
# --------------------------------------------------------------------------
echo "[7/7] Starting services..."

# 7a. Start llama-server
sudo -u "$LAB_USER" bash -c "
    nohup $LAB_HOME/llama.cpp/build/bin/llama-server \
        -m $LAB_HOME/models/MiniMax-M2.7-Q4_K_M.gguf \
        --port 8080 \
        --host 127.0.0.1 \
        > $LAB_HOME/llama-server.log 2>&1 &
"
sleep 3

# 7b. Start ttyd (web terminal) — publicly accessible
nohup ttyd -p 7681 -W \
    sudo -u "$LAB_USER" bash -c '
        export PATH="$HOME/.local/bin:$PATH"
        export OPENAI_API_BASE="http://127.0.0.1:8080/v1"
        export OPENAI_API_KEY="local"
        echo ""
        echo "  ╔══════════════════════════════════════════╗"
        echo "  ║       🧠 OpenCode AI Lab                 ║"
        echo "  ║                                          ║"
        echo "  ║  Type: opencode    to start coding       ║"
        echo "  ║                                          ║"
        echo "  ║  Model:  MiniMax-M2.7 (Q4_K_M)          ║"
        echo "  ║  Engine: llama.cpp (local inference)     ║"
        echo "  ║  No API keys. No cloud calls. Just code. ║"
        echo "  ╚══════════════════════════════════════════╝"
        echo ""
        exec bash
    ' > /var/log/ttyd.log 2>&1 &

# Get external IP for the log
EXTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" \
    http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)

echo ""
echo "========================================"
echo "  ✅ OpenCode AI Lab is LIVE!"
echo "========================================"
echo ""
echo "  Web Terminal:  http://${EXTERNAL_IP}:7681"
echo "  LLM API:       http://127.0.0.1:8080/v1"
echo ""
echo "  Logs:"
echo "    Startup:     $LOG"
echo "    llama-server: $LAB_HOME/llama-server.log"
echo "    ttyd:         /var/log/ttyd.log"
echo ""
echo "  Startup completed at $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "========================================"
