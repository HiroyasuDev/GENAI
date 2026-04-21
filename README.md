# 🧠 OpenCode AI Lab

> **A turnkey GCP VM startup script that deploys a fully local AI coding assistant — MiniMax-M2.7 + llama.cpp + OpenCode TUI — in a branded tmux workspace. No API keys. No cloud inference. Just code.**

---

## 🎯 What Is This?

OpenCode AI Lab is a **self-hosted, zero-dependency AI pair-programming environment** that runs entirely on a single GCP VM. It combines:

| Component | Role |
|-----------|------|
| **[MiniMax-M2.7](https://huggingface.co/unsloth/MiniMax-M2.7-GGUF)** | 2.7B parameter LLM (Q4_K_M quantized) |
| **[llama.cpp](https://github.com/ggml-org/llama.cpp)** | High-performance C++ inference engine |
| **[OpenCode](https://opencode.ai)** | Agentic terminal UI for AI-assisted coding |
| **tmux** | Branded, split-pane workspace orchestration |

No OpenAI. No Anthropic. No API keys. **100% local inference.**

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────┐
│                 GCP VM (US-Central1)            │
│                                                 │
│  ┌──────────────────┐  ┌──────────────────────┐ │
│  │   PANE 0          │  │   PANE 1              │ │
│  │                   │  │                       │ │
│  │  llama-server     │  │  OpenCode TUI         │ │
│  │  :8080/v1         │──│  OPENAI_API_BASE=     │ │
│  │                   │  │  localhost:8080/v1     │ │
│  │  MiniMax-M2.7     │  │                       │ │
│  │  Q4_K_M (GGUF)    │  │  Agentic Coding       │ │
│  └──────────────────┘  └──────────────────────┘ │
│                                                 │
│  ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄ │
│  LAB: OPENCODE │ MINIMAX-M2.7   GCP-US  15:30  │
│  ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ │
│                    tmux status bar               │
└─────────────────────────────────────────────────┘
```

---

## 🚀 Quick Start

### 1. Create a GCP VM

```bash
# e2-standard-4 or better recommended
# Ubuntu 22.04 LTS
# At least 16GB RAM for comfortable inference
```

### 2. Deploy the Lab (one command)

```bash
# As VM startup script, or run manually after SSH:
chmod +x opencode_lab/vm_startup.sh
./opencode_lab/vm_startup.sh
```

### 3. Install the Stack

```bash
cd ~/opencode_lab
./setup_stack.sh
```

This will:
- Install system dependencies (build-essential, git, curl, tmux)
- Install Google Cloud SDK
- Install [OpenCode](https://opencode.ai) agentic TUI
- Download MiniMax-M2.7-Q4_K_M.gguf (~1.6GB) from HuggingFace
- Build llama.cpp from source

### 4. Launch

```bash
./start_lab.sh
```

This starts a branded tmux session with:
- **Left pane**: llama-server running inference on port 8080
- **Right pane**: OpenCode TUI connected to the local endpoint

---

## 📁 File Structure

```
opencode_lab/
├── vm_startup.sh     # GCP VM startup script (bootstraps everything)
├── setup_stack.sh    # Full stack installer (deps + model + inference engine)
├── start_lab.sh      # Launch script (tmux + llama-server + OpenCode)
└── .tmux.conf        # Branded tmux status bar config
```

---

## ⚙️ Configuration

### GPU Acceleration

If your VM has a GPU (A100, L4, T4), edit `setup_stack.sh`:

```diff
- make -j
+ make -j LLAMA_CUDA=1
```

### Different Model

Swap the model in `setup_stack.sh`:

```bash
# Example: Use a different GGUF model
huggingface-cli download <org>/<model> <filename>.gguf --local-dir models
```

Then update the model path in `start_lab.sh`.

### Port Configuration

The inference server defaults to port `8080`. Change in both `start_lab.sh` and the `OPENAI_API_BASE` export.

---

## 🔒 Security Note

This lab is designed for **ephemeral, single-user environments** (lab VMs, cloud training sandboxes). The inference server binds to `localhost` only. Do not expose port 8080 to the public internet without authentication.

---

## 📝 License

MIT

---

## 🤙 Built With Aloha

Created during a GCP lab session as a proof-of-concept for self-hosted AI coding workflows.
No cloud APIs were harmed in the making of this lab.
