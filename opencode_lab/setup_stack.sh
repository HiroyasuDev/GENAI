#!/bin/bash
set -e

echo "Starting OpenCode + MiniMax Local Stack Installation..."

# 1. System Updates & Dependencies
echo "Installing dependencies..."
sudo apt update && sudo apt install -y build-essential git curl python3-pip apt-transport-https ca-certificates gnupg

# 2. Install Google Cloud SDK (gcloud CLI)
echo "Installing Google Cloud SDK..."
# Add the Cloud SDK distribution URI as a package source
sudo apt-get install -y lsb-release
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo bash -c "echo 'deb https://packages.cloud.google.com/apt cloud-sdk main' > /etc/apt/sources.list.d/google-cloud-sdk.list"
sudo apt-get update && sudo apt-get install -y google-cloud-sdk

# 3. OpenCode Agent
echo "Installing OpenCode..."
curl -fsSL https://opencode.ai/install | bash

# 4. Download Model via HuggingFace
echo "Installing huggingface-cli and downloading MiniMax..."
pip3 install huggingface_hub
mkdir -p models
# Using standard model directory and quantizing as per instructions
huggingface-cli download unsloth/MiniMax-M2.7-GGUF MiniMax-M2.7-Q4_K_M.gguf --local-dir models

# 5. Build Inference Engine (llama.cpp)
echo "Building llama.cpp..."
git clone https://github.com/ggml-org/llama.cpp
cd llama.cpp
# Note: For GPU instances (e.g. A100/L4), change this to: make -j LLAMA_CUDA=1
make -j
cd ..

# 6. Verify gcloud installation (optional)
if command -v gcloud >/dev/null 2>&1; then
  echo "gcloud CLI installed successfully."
  gcloud version
else
  echo "gcloud CLI installation failed."
fi

echo "Setup complete! You can now run start_lab.sh."
