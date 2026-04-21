# 🧠 OpenCode AI Lab

> **A turnkey GCP VM startup script that deploys a fully local AI coding assistant — MiniMax-M2.7 + llama.cpp + OpenCode TUI — in a branded tmux workspace. No API keys. No cloud inference. Just code.**

### 🚀 [Launch Live Lab](https://hiroyasudev.github.io/GENAI/)

---

## 🎯 What Is This?

OpenCode AI Lab is a **self-hosted, zero-dependency AI pair-programming environment** that runs entirely on a single GCP VM. It combines:

| Component | Role |
|-----------|------|
| **[MiniMax-M2.7](https://huggingface.co/unsloth/MiniMax-M2.7-GGUF)** | 2.7B parameter LLM (Q4_K_M quantized) |
| **[llama.cpp](https://github.com/ggml-org/llama.cpp)** | High-performance C++ inference engine |
| **[OpenCode](https://opencode.ai)** | Agentic terminal UI for AI-assisted coding |
| **[ttyd](https://github.com/tsl0922/ttyd)** | Browser-based terminal (zero-install access) |
| **tmux** | Branded, split-pane workspace orchestration |

No OpenAI. No Anthropic. No API keys. **100% local inference.**

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────┐
│                   GCP VM (e2-standard-4)             │
│                                                      │
│  ┌──────────────┐     ┌───────────────────────────┐  │
│  │ llama-server  │     │  ttyd (web terminal)      │  │
│  │ :8080/v1      │◄────│  :7681 (public)           │  │
│  │               │     │                           │  │
│  │ MiniMax-M2.7  │     │  ┌─────────────────────┐  │  │
│  │ Q4_K_M (GGUF) │     │  │   OpenCode TUI      │  │  │
│  └──────────────┘     │  │   (agentic coding)   │  │  │
│                        │  └─────────────────────┘  │  │
│                        └───────────────────────────┘  │
│                                                      │
│  Browser ──► http://<EXTERNAL_IP>:7681 ──► OpenCode  │
└──────────────────────────────────────────────────────┘
```

---

## ⚡ One-Click Deploy (Terraform)

Spin up the entire lab from scratch in **~5 minutes**.

### Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) installed
- [gcloud CLI](https://cloud.google.com/sdk/docs/install) authenticated
- A GCP project with **Compute Engine API** enabled

### Deploy

```powershell
# Option A: One-liner (PowerShell)
.\deploy.ps1 -ProjectId "your-gcp-project-id"

# Option B: Manual
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your project ID
terraform init
terraform apply
```

### What Happens

1. Terraform creates a **GCP VM** (e2-standard-4, 16 GB RAM, Ubuntu 22.04)
2. A **static external IP** is reserved
3. **Firewall rules** open ports 22 (SSH) and 7681 (web terminal)
4. The **startup script** runs automatically:
   - Installs system deps + cmake
   - Installs ttyd (web terminal)
   - Installs OpenCode
   - Downloads MiniMax-M2.7 (~1.6 GB)
   - Builds llama.cpp from source
   - Starts llama-server + ttyd
5. Terraform outputs the **public URL**

### Access

```
http://<EXTERNAL_IP>:7681
```

Open in any browser → type `opencode` → start coding with AI.

### Monitor Startup Progress

```bash
gcloud compute ssh opencode-lab-vm --zone=us-central1-a -- tail -f /var/log/opencode-lab-startup.log
```

### Teardown

```bash
cd terraform
terraform destroy -auto-approve
```

---

## 📂 Project Structure

```
GENAI/
├── deploy.ps1                    # One-click deploy (PowerShell)
├── README.md
├── docs/
│   └── index.html                # GitHub Pages landing page
├── opencode_lab/
│   ├── vm_startup.sh             # Original VM startup script
│   ├── setup_stack.sh            # Manual stack installer
│   ├── start_lab.sh              # Manual launch script
│   └── .tmux.conf                # tmux config
└── terraform/
    ├── main.tf                   # GCP VM + firewall + static IP
    ├── variables.tf              # Configurable variables
    ├── outputs.tf                # Lab URL, SSH command, etc.
    ├── startup.sh                # Automated full-stack installer
    ├── terraform.tfvars.example  # Example variables
    └── .gitignore                # Excludes state files
```

---

## ⚙️ Configuration

### GPU Acceleration

For faster inference, use a GPU machine type:

```hcl
# In terraform.tfvars
machine_type = "g2-standard-4"   # 1x NVIDIA L4 GPU
```

Then update `startup.sh` to build with CUDA:

```bash
cmake -B build -DGGML_CUDA=ON
```

### Different Model

Edit `terraform/startup.sh` to swap the model:

```bash
huggingface-cli download <org>/<model> <filename>.gguf --local-dir $LAB_HOME/models
```

### Restrict Access

```hcl
# In terraform.tfvars — limit to specific IPs
allowed_source_ranges = ["203.0.113.0/24", "198.51.100.42/32"]
```

---

## 🔒 Security Notes

- The inference server binds to `localhost` only (not publicly exposed)
- Only the ttyd web terminal (port 7681) is public
- Use `allowed_source_ranges` to restrict access by IP
- For production, add TLS termination and authentication

---

## 📝 License

MIT

---

## 🤙 Built With Aloha

Created as a proof-of-concept for self-hosted AI coding workflows.
No cloud APIs were harmed in the making of this lab.
