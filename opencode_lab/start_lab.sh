#!/bin/bash
set -e

# Ensure tmux config is loaded
TMUX_CONF="$HOME/.tmux.conf"
if [ -f "$TMUX_CONF" ]; then
  tmux source-file "$TMUX_CONF"
fi

# Start a new detached tmux session named opencode-lab (or attach if exists)
SESSION_NAME="opencode-lab"
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  echo "Session $SESSION_NAME already exists. Attaching..."
  tmux attach -t "$SESSION_NAME"
  exit 0
fi

tmux new-session -d -s "$SESSION_NAME" -n "inference"

# Pane 1: Inference server (llama.cpp)
# Change to directory where llama.cpp was built
cd "$HOME/opencode_lab/llama.cpp" || exit 1
# Run inference server on port 8080 (adjust GPU layers if needed)
./llama-server -m "$HOME/opencode_lab/models/MiniMax-M2.7-Q4_K_M.gguf" --port 8080 --n-gpu-layers 99 &

# Return to project root and split window for OpenCode UI
cd "$HOME/opencode_lab"

tmux split-window -h -t "$SESSION_NAME:0" -n "opencode"

tmux select-pane -t "$SESSION_NAME:0.1"
# Export environment variables for OpenCode to use local server
export OPENAI_API_BASE="http://127.0.0.1:8080/v1"
export OPENAI_API_KEY="local"

# Launch OpenCode TUI (will use the local llama endpoint)
opencode

# After OpenCode exits, keep the session alive for debugging
tmux attach -t "$SESSION_NAME"
