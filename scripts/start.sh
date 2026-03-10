#!/bin/bash
set -e

# ── Persistent volume setup ──────────────────────────────────
# Models and user settings live on /storage (persistent volume).
# Output and input stay on the container's ephemeral disk.
# Gen-studio pulls results via SSH before the pod stops.

# ── SSH setup (base image has openssh but no host keys) ──────
mkdir -p /var/run/sshd
ssh-keygen -A 2>/dev/null
grep -q 'PermitRootLogin yes' /etc/ssh/sshd_config || echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config

mkdir -p /storage/models /storage/user

# Symlink only user settings to persistent storage
if [ ! -L /ComfyUI/user ]; then
    rm -rf /ComfyUI/user
    ln -s /storage/user /ComfyUI/user
fi

# Create model subdirs on persistent volume if they don't exist
for d in checkpoints loras vae controlnet clip clip_vision configs \
         diffusion_models embeddings style_models text_encoders unet \
         upscale_models FBCNN mmaudio rembg sams ultralytics; do
    mkdir -p "/storage/models/$d"
done

echo "=== ComfyUI RTX 5090 Optimized ==="
echo "PyTorch: $(python -c 'import torch; print(torch.__version__)')"
echo "CUDA:    $(python -c 'import torch; print(torch.version.cuda)')"
echo "Models:  /storage/models (persistent)"
echo "Output:  /ComfyUI/output (ephemeral)"
echo "==================================="

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
