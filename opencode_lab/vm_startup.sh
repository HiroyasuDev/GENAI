#!/bin/bash
set -e

LABDIR="/home/cloud_user_p_f9f49ed7/opencode_lab"
mkdir -p "$LABDIR"

# Write .tmux.conf
cat > "$LABDIR/.tmux.conf" << 'EOF'
set -g status-interval 2
set -g status-style bg=default
set -g status-left-length 60
set -g status-left "#[fg=magenta,bold] LAB: OPENCODE #[fg=white]| #[fg=cyan]MINIMAX-M2.7 "
set -g status-right "#[fg=yellow,bold] GCP-US-CENTRAL1 #[fg=green]%H:%M:%S "
set -g mouse on
EOF

# Write setup_stack.sh
cat > "$LABDIR/setup_stack.sh" << 'EOF'
#!/bin/bash
set -e
echo "Installing dependencies..."
sudo apt update && sudo apt install -y build-essential git curl python3-pip tmux apt-transport-https ca-certificates gnupg

echo "Installing Google Cloud SDK..."
sudo apt-get install -y lsb-release
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
sudo apt-get update && sudo apt-get install -y google-cloud-sdk

echo "Installing OpenCode..."
curl -fsSL https://opencode.ai/install | bash || true

echo "Setup complete! Run ./start_lab.sh to launch."
EOF

# Write start_lab.sh
cat > "$LABDIR/start_lab.sh" << 'EOF'
#!/bin/bash
set -e

cp "$HOME/opencode_lab/.tmux.conf" "$HOME/.tmux.conf"
tmux source-file "$HOME/.tmux.conf" 2>/dev/null || true

SESSION="opencode-lab"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "Session exists. Attaching..."
  tmux attach -t "$SESSION"
  exit 0
fi

tmux new-session -d -s "$SESSION" -n "lab"

# Pane 0: Ready for inference server
tmux send-keys -t "$SESSION:0.0" "echo 'Inference pane ready. Start llama-server here.'" C-m

# Split and create Pane 1: Ready for OpenCode
tmux split-window -h -t "$SESSION"
tmux send-keys -t "$SESSION:0.1" "export OPENAI_API_BASE='http://localhost:8080/v1' && export OPENAI_API_KEY='local' && echo 'OpenCode pane ready. Run: opencode'" C-m

tmux attach -t "$SESSION"
EOF

chmod +x "$LABDIR/setup_stack.sh" "$LABDIR/start_lab.sh"
chown -R cloud_user_p_f9f49ed7:cloud_user_p_f9f49ed7 "$LABDIR" 2>/dev/null || true

echo "Lab files deployed to $LABDIR"
