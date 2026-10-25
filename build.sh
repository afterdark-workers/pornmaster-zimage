#!/bin/sh
# PornMaster Z-Image Turbo — everything the worker image needs. The Dockerfile in your copy downloads this file
# from the original repo on every build, so fixes made there reach you with a rebuild.
set -eu
case "${CIVITAI_TOKEN:-}" in ""|PASTE_*) echo "ERROR: set CIVITAI_TOKEN at the top of the Dockerfile" >&2; exit 1;; esac

# file <dest> <url> <sha256>
file() {
  wget -q -O "$1" "$2"
  echo "$3  $1" | sha256sum -c - || { echo "ERROR: $1 changed upstream — wait for an update of the original repo, then rebuild" >&2; exit 1; }
}

# Civitai 2270401 / version 2903129 (11.5 GB)
file /comfyui/models/diffusion_models/pornmaster_zit_v35_bf16.safetensors \
  "https://civitai.com/api/download/models/2903129?fileId=2781142&token=${CIVITAI_TOKEN}" \
  4cc3baec019603f86e054ca0df8a036f17da984d8c4091b717c2a9256d0d4b15

# Comfy-Org/Z-Image-Turbo (Apache 2.0) (5.6 GB)
file /comfyui/models/text_encoders/qwen_3_4b_fp8_mixed.safetensors \
  "https://huggingface.co/Comfy-Org/Z-Image-Turbo/resolve/6fc90a3b1b653e935a0d175e260736de25b84df5/split_files/text_encoders/qwen_3_4b_fp8_mixed.safetensors" \
  72450b19758172c5a7273cf7de729d1c17e7f434a104a00167624cba94f68f15

# Comfy-Org/Z-Image-Turbo (0.3 GB)
file /comfyui/models/vae/ae.safetensors \
  "https://huggingface.co/Comfy-Org/Z-Image-Turbo/resolve/6fc90a3b1b653e935a0d175e260736de25b84df5/split_files/vae/ae.safetensors" \
  afc8e28272cd15db3919bacdb6918ce9c1ed22e96cb12c4d5ed0fba823529e38

# ComfyUI 0.34.0 (base image) → 0.39.0 — Z-Image needs 0.36+. Install into /opt/venv (the one ComfyUI actually runs with).
cd /comfyui
git fetch --depth 1 https://github.com/Comfy-Org/ComfyUI.git tag v0.39.0
git checkout -f v0.39.0
uv pip install --python /opt/venv/bin/python -r requirements.txt "transformers>=4.50.3,<5" "huggingface-hub<1.0"
timeout 300 /opt/venv/bin/python main.py --quick-test-for-ci --cpu
