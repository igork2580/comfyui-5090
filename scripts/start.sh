#!/bin/bash
set -e

# ── Persistent volume setup ──────────────────────────────────
# Models and user settings live on /storage (persistent volume).
# Output and input stay on the container's ephemeral disk.
# Gen-studio pulls results via SSH before the pod stops.

# ── SSH setup (base image has openssh but needs configuration) ──
mkdir -p /var/run/sshd
ssh-keygen -A 2>/dev/null
# Allow root login with password (SimplePod uses hashId as password)
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
grep -q '^PermitRootLogin yes' /etc/ssh/sshd_config || echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
grep -q '^PasswordAuthentication yes' /etc/ssh/sshd_config || echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config

mkdir -p /storage/models /storage/user

# Symlink only user settings to persistent storage
if [ ! -L /ComfyUI/user ]; then
    rm -rf /ComfyUI/user
    ln -s /storage/user /ComfyUI/user
fi

# Create model subdirs on persistent volume if they don't exist
for d in checkpoints loras vae controlnet clip clip_vision configs \
         diffusion_models embeddings style_models text_encoders unet \
         upscale_models latent_upscale_models FBCNN mmaudio rembg sams ultralytics BiRefNet; do
    mkdir -p "/storage/models/$d"
done

# Impact-Pack's UltralyticsDetectorProvider ignores extra_model_paths.yaml
# and only looks in /ComfyUI/models/ultralytics/. Symlink from persistent storage.
for subdir in bbox segm; do
    mkdir -p "/storage/models/ultralytics/$subdir"
    mkdir -p "/ComfyUI/models/ultralytics/$subdir"
    for f in "/storage/models/ultralytics/$subdir"/*; do
        [ -e "$f" ] || continue
        target="/ComfyUI/models/ultralytics/$subdir/$(basename "$f")"
        [ -e "$target" ] || ln -s "$f" "$target"
    done
done

# Symlink VAE files to root so workflows can reference with or without LTX2/ prefix
for f in /storage/models/vae/LTX2/*.safetensors; do
    [ -e "$f" ] || continue
    target="/storage/models/vae/$(basename "$f")"
    [ -e "$target" ] || ln -s "$f" "$target"
done

# LayerStyle-Advance's LoadBiRefNetModelV2 hardcodes /ComfyUI/models/BiRefNet/
# (ignores extra_model_paths.yaml). Symlink to persistent storage.
if [ ! -L /ComfyUI/models/BiRefNet ]; then
    rm -rf /ComfyUI/models/BiRefNet
    ln -s /storage/models/BiRefNet /ComfyUI/models/BiRefNet
fi
# That node has a bug: for version "BiRefNet-General" it never auto-downloads —
# it just from_pretrained()s models/BiRefNet/BiRefNet-General/ which must already
# exist. Pre-fetch it once per persistent volume (~430 MB; quick when present).
if [ ! -f /storage/models/BiRefNet/BiRefNet-General/config.json ]; then
    echo "Fetching BiRefNet-General (ZhengPeng7/BiRefNet)..."
    python -c "from huggingface_hub import snapshot_download; snapshot_download('ZhengPeng7/BiRefNet', local_dir='/storage/models/BiRefNet/BiRefNet-General', ignore_patterns=['*.md','*.txt','.gitattributes'])" || true
fi

# SageAttention 1.x has no Blackwell (sm_12x) kernels — it segfaults ComfyUI on
# RTX 5090 when a model tries to use it (no Python error, the process just dies).
# On Blackwell, remove it so ComfyUI falls back to PyTorch attention. (On Ada /
# Ampere — e.g. RTX 4090 — it works fine, so keep it there for the ~2x speedup.)
CC_MAJOR=$(python -c "import torch; print(torch.cuda.get_device_capability(0)[0])" 2>/dev/null || echo 0)
if [ "${CC_MAJOR:-0}" -ge 12 ]; then
    echo "Blackwell GPU (sm_${CC_MAJOR}x) detected — removing sageattention (segfaults on Blackwell)"
    pip uninstall -y sageattention >/dev/null 2>&1 || true
fi

echo "=== ComfyUI RTX 5090 Optimized ==="
echo "PyTorch: $(python -c 'import torch; print(torch.__version__)')"
echo "CUDA:    $(python -c 'import torch; print(torch.version.cuda)')"
echo "Models:  /storage/models (persistent)"
echo "Output:  /ComfyUI/output (ephemeral)"
echo "==================================="

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
