#!/bin/bash
set -e

# ── Create symlinks for persistent volume ───────────────────
# Models, output, and input live on /storage (SimplePod persistent volume).
# ComfyUI reads models via extra_model_paths.yaml.
# Output and input are symlinked.

mkdir -p /storage/models /storage/output /storage/input /storage/user

# Symlink output + input to persistent storage
if [ ! -L /app/ComfyUI/output ]; then
    rm -rf /app/ComfyUI/output
    ln -s /storage/output /app/ComfyUI/output
fi

if [ ! -L /app/ComfyUI/input ]; then
    rm -rf /app/ComfyUI/input
    ln -s /storage/input /app/ComfyUI/input
fi

if [ ! -L /app/ComfyUI/user ]; then
    rm -rf /app/ComfyUI/user
    ln -s /storage/user /app/ComfyUI/user
fi

# Create model subdirs on persistent volume if they don't exist
for d in checkpoints loras vae controlnet clip clip_vision diffusion_models \
         embeddings style_models text_encoders unet upscale_models; do
    mkdir -p "/storage/models/$d"
done

echo "=== ComfyUI RTX 5090 Optimized ==="
echo "PyTorch: $(python -c 'import torch; print(torch.__version__)')"
echo "CUDA:    $(python -c 'import torch; print(torch.version.cuda)')"
echo "Models:  /storage/models"
echo "Output:  /storage/output"
echo "==================================="

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
