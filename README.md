# ComfyUI RTX 5090 (Blackwell) — Optimized Docker Template

Production-ready ComfyUI Docker image optimized for RTX 5090 with NVFP4 quantization support.

## Stack

| Component | Version | Why |
|---|---|---|
| CUDA | 13.0 | Required for NVFP4 (2-3x speedup on Blackwell) |
| Python | 3.12 | Best compatibility with custom nodes |
| PyTorch | Nightly cu130 | Only nightly supports sm_120 (Blackwell) |
| Attention | SDPA + SageAttention | ~2x faster than xformers on 5090 |
| xformers | **NOT INSTALLED** | Silently downgrades PyTorch, slower on Blackwell |

## What's included

- **74 custom nodes** (29 git-cloned + 45 CNR-managed) — all deps baked in, no boot scripts
- ComfyUI-Manager for easy node management in the browser
- SageAttention 2.x for accelerated attention
- JupyterLab for easy file/model management
- SSH + Supervisor for cloud pod management

## How it works

The image separates **code** (baked into Docker) from **data** (on persistent volume):

```
Docker Image (immutable, fast boot):         Persistent Volume (/storage):
├── /app/ComfyUI/                            ├── models/
│   ├── main.py                              │   ├── checkpoints/
│   ├── custom_nodes/ (74 nodes + deps)      │   ├── loras/
│   ├── extra_model_paths.yaml ──────────────│── │   ├── vae/
│   └── ...                                  │   ├── controlnet/
├── PyTorch cu130                            │   ├── clip/
├── SageAttention                            │   ├── diffusion_models/
├── JupyterLab                               │   ├── embeddings/
└── supervisor (ComfyUI + Jupyter + SSH)     │   └── upscale_models/
                                             ├── output/ ← symlinked
                                             ├── input/  ← symlinked
                                             └── user/   ← ComfyUI settings
```

**How ComfyUI finds your models:** The file `extra_model_paths.yaml` (baked into the image) tells ComfyUI to look for models in `/storage/models/` in addition to the default paths. This is an official ComfyUI feature — it merges both locations, so models are found automatically.

**How output/input persist:** On first boot, `start.sh` creates symlinks:
- `/app/ComfyUI/output` → `/storage/output`
- `/app/ComfyUI/input` → `/storage/input`
- `/app/ComfyUI/user` → `/storage/user`

This means your generated images and ComfyUI settings survive pod restarts.

## SimplePod Setup (step by step)

### 1. Create a Persistence Volume

Go to SimplePod dashboard → Persistence Volumes → Create:
- **Size**: 200GB (or more depending on your models)
- **Datacenter**: EU-PL-01 (must match your instances)

### 2. Create a Template

Go to Templates → Create Custom Template:

| Field | Value |
|---|---|
| **Image Name** | `igork2580/comfyui-5090` |
| **Image Tag** | `latest` |
| **System disk** | 40 GB |
| **Persistence Volume** | Select the volume you created |
| **Mount Point** | `/storage` |
| **Expose Ports** | `8188, 8888, 22` |

The mount point `/storage` is critical — this is where the image expects to find models and write output.

### 3. Launch an instance

Select your template, pick an RTX 5090 GPU, and start. On first boot:
- `start.sh` creates the directory structure inside `/storage`
- ComfyUI starts on port 8188
- JupyterLab starts on port 8888
- SSH is available on port 22

### 4. Upload your models

Use JupyterLab (port 8888) to upload models, or SSH in:

```bash
# Via SSH — copy models from your machine
scp -P <ssh_port> my_checkpoint.safetensors root@<pod_ip>:/storage/models/checkpoints/

# Or from inside the pod — download from HuggingFace/CivitAI
cd /storage/models/checkpoints
wget https://...
```

Model directory mapping:

| Model type | Put files in |
|---|---|
| Checkpoints | `/storage/models/checkpoints/` |
| LoRAs | `/storage/models/loras/` |
| VAE | `/storage/models/vae/` |
| ControlNet | `/storage/models/controlnet/` |
| CLIP | `/storage/models/clip/` |
| Embeddings | `/storage/models/embeddings/` |
| Upscale | `/storage/models/upscale_models/` |
| Diffusion models | `/storage/models/diffusion_models/` |
| Text encoders | `/storage/models/text_encoders/` |

### 5. Open ComfyUI

Go to the ComfyUI port (8188) in your browser. Your models will appear in all the dropdown menus automatically.

## Migrating from existing setup

If you have models on an existing SimplePod volume mounted at `/app`:

1. Start a pod with the OLD template
2. SSH in and copy models to the new volume:
```bash
# If new volume is also mounted (e.g. at /storage):
cp -r /app/ComfyUI/models/* /storage/models/

# Or rsync to be safe:
rsync -av /app/ComfyUI/models/ /storage/models/
```

## Ports

| Port | Service | Purpose |
|---|---|---|
| 8188 | ComfyUI | Main UI + API |
| 8888 | JupyterLab | File manager, upload models, browse output |
| 22 | SSH | Remote access, scripting |

## Why not xformers?

On RTX 5090 (Blackwell), xformers:
1. **Silently downgrades PyTorch** from cu130 to cu128 via dependency chain (breaks NVFP4)
2. **Has no prebuilt wheels** for sm_120 — must build from source
3. **Is slower** than PyTorch SDPA + SageAttention on Blackwell

Benchmarks: xformers 5.194ms vs SDPA 5.049ms vs SageAttention 2.671ms

The image uses PyTorch's built-in SDPA (Scaled Dot-Product Attention) as default, with SageAttention available for an additional ~2x speedup on attention operations.

## Updating custom nodes

**Update a git-cloned node:** Change its commit hash in the Dockerfile and rebuild.

**Add a new CNR node:** Add it to the `comfy node install` list in the Dockerfile.

**Add a new git node:**
```dockerfile
RUN git clone https://github.com/author/ComfyUI-NewNode.git && \
    cd ComfyUI-NewNode && git checkout <commit_hash> && cd ..
```

After any change, push to trigger a rebuild via GitHub Actions.

## Building locally

```bash
docker build -t igork2580/comfyui-5090:latest .
docker push igork2580/comfyui-5090:latest
```

## License

MIT
