#!/usr/bin/env bash
set -e

# ----------------------------------------------------------------------
# 1️⃣  Launch the LLM inference server (llama.cpp)
# ----------------------------------------------------------------------
MODEL_PATH="/opt/models/MiniMax-M2.7/ggml-model-q4_k_m.gguf"
PORT=8080

echo "▶️ Starting llama-server on ${PORT} ..."
/opt/llama.cpp/llama-server -m "${MODEL_PATH}" --port "${PORT}" --n-gpu-layers 99 &

# Give the server a moment to bind
sleep 2

# ----------------------------------------------------------------------
# 2️⃣  Run OpenCode (it will read OPENAI_API_BASE/KEY env vars)
# ----------------------------------------------------------------------
echo "▶️ Launching OpenCode TUI …"
opencode &

# ----------------------------------------------------------------------
# 3️⃣  Expose a browser‑based terminal (ttyd) that connects to the
#     OpenCode process.  ttyd will listen on port 7681.
# ----------------------------------------------------------------------
echo "▶️ Starting ttyd (web terminal) on http://0.0.0.0:7681 ..."
ttyd -p 7681 bash -c "export OPENAI_API_BASE=http://127.0.0.1:${PORT}/v1; export OPENAI_API_KEY=local; exec bash"
