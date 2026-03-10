# ComfyUI RTX 5090 (Blackwell) Docker Template

Production-ready ComfyUI image optimized for RTX 5090 with NVFP4 quantization support.

## Stack

| Component | Version | Why |
|---|---|---|
| CUDA | 13.0 | Required for NVFP4 (2-3x speedup on Blackwell) |
| Python | 3.12 | Via deadsnakes PPA on Ubuntu 22.04 |
| PyTorch | Nightly cu130 | Only nightly supports sm_120 (Blackwell) |
| Base image | `devel` | Includes gcc + nvcc for compiling SageAttention and custom node C extensions |
| Attention | SDPA + SageAttention | ~2x faster than xformers on 5090 |
| xformers | **NOT INSTALLED** | Silently downgrades PyTorch, slower on Blackwell |

## What's included

- **74 custom nodes** (29 git-cloned + 45 CNR-managed), all deps baked in
- ComfyUI-Manager for browser-based node management
- SageAttention 2.x for accelerated attention
- JupyterLab for file/model management
- SSH + Supervisor for cloud pod management

## Architecture: Code vs Data

The image separates **code** (baked into Docker, immutable) from **data** (on a persistent volume, survives reboots). This is the core design decision. You never lose models, outputs, or settings when you rebuild the image or restart a pod.

```
Docker Image (immutable):                   Persistent Volume (/storage):
├── /app/ComfyUI/                            ├── models/
│   ├── main.py                              │   ├── checkpoints/
│   ├── custom_nodes/ (74 nodes + deps)      │   ├── loras/
│   ├── extra_model_paths.yaml ─────────────►│   ├── vae/
│   └── ...                                  │   ├── controlnet/
├── PyTorch cu130 + SageAttention            │   ├── clip/
├── JupyterLab                               │   ├── clip_vision/
└── supervisor (ComfyUI + Jupyter + SSH)     │   ├── diffusion_models/
                                             │   ├── embeddings/
                                             │   ├── style_models/
                                             │   ├── text_encoders/
                                             │   ├── unet/
                                             │   └── upscale_models/
                                             ├── output/ ← symlinked from /app/ComfyUI/output
                                             ├── input/  ← symlinked from /app/ComfyUI/input
                                             └── user/   ← ComfyUI settings + workflows
```

## Persistent Storage (in depth)

The persistent volume is the single most important thing to understand. Everything inside the Docker image gets wiped on rebuild. Everything on the persistent volume stays forever (or until you delete it).

### How the mount works

SimplePod (or any Docker host) mounts a persistent disk at `/storage` inside the container. You configure this when creating a pod template. The Docker image itself doesn't know or care about the volume; it just expects `/storage` to exist at runtime. If it doesn't, `start.sh` still creates the directories, but they'll only live on the container's ephemeral disk and vanish on restart.

### How ComfyUI discovers models

ComfyUI has a built-in feature called `extra_model_paths.yaml`. This file tells ComfyUI to scan additional directories for models, on top of its default `models/` folder. The image bakes in a config that points every model type to `/storage/models/<type>/`:

```yaml
storage:
    base_path: /storage/models
    checkpoints: checkpoints/
    loras: loras/
    vae: vae/
    controlnet: controlnet/
    # ... and so on for every model type
```

ComfyUI merges these paths with its defaults. Drop a `.safetensors` file into the right folder, and it shows up in the UI dropdown immediately (or after a browser refresh). No restart needed.

### Model directories explained

| Directory | What goes here | Typical file sizes | Examples |
|---|---|---|---|
| `checkpoints/` | Full model weights (SD 1.5, SDXL, Flux, HunyuanVideo). These are the main generation models. | 2-12 GB each | `realisticVisionV60.safetensors`, `flux1-dev.safetensors` |
| `loras/` | LoRA adapters that modify checkpoint behavior. Style, character, or concept fine-tunes. | 10-250 MB each | `add_detail.safetensors`, `character_jane.safetensors` |
| `vae/` | Variational autoencoders. Convert latent space to/from pixel images. Most checkpoints bundle their own VAE, so you only need standalone files for specific overrides. | 300-800 MB | `vae-ft-mse-840000.safetensors` |
| `controlnet/` | ControlNet models for guided generation (pose, depth, canny edges, etc.). | 700 MB - 2.5 GB | `control_v11p_sd15_openpose.safetensors` |
| `clip/` | CLIP text encoder weights. Needed when a checkpoint doesn't bundle its own text encoder (common with Flux and SD3). | 200 MB - 5 GB | `clip_l.safetensors`, `t5xxl_fp16.safetensors` |
| `clip_vision/` | CLIP vision encoders for image-to-image workflows like IP-Adapter. | 600 MB - 2 GB | `CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors` |
| `diffusion_models/` | Standalone diffusion model weights (UNet or DiT) without text encoders or VAE. Used by Flux, HunyuanVideo, and similar architectures that split components. | 5-25 GB | `flux1-dev.safetensors`, `hunyuan_video.safetensors` |
| `embeddings/` | Textual inversions (also called embeddings or TI). Small files that add trained concepts to the text encoder. | 10-100 KB | `easynegative.safetensors`, `bad_hands.pt` |
| `style_models/` | Style transfer models used by certain custom nodes. | 200 MB - 1 GB | Rare, leave empty unless a workflow specifically needs one |
| `text_encoders/` | Standalone text encoder weights. Similar to `clip/` but used by newer architectures that refer to them as text encoders. | 500 MB - 10 GB | `t5xxl_fp8_e4m3fn.safetensors` |
| `unet/` | Standalone UNet weights. Legacy directory; newer models use `diffusion_models/` instead. | 2-10 GB | Some older SDXL workflows reference this path |
| `upscale_models/` | Super-resolution models for upscaling generated images 2x or 4x. | 50-200 MB | `4x-UltraSharp.pth`, `RealESRGAN_x4plus.pth` |

### Subfolder conventions

You can create subfolders inside any model directory. ComfyUI scans recursively, so organizing by category works fine:

```
/storage/models/
├── checkpoints/
│   ├── sd15/
│   │   └── realisticVision.safetensors
│   ├── sdxl/
│   │   └── juggernautXL.safetensors
│   └── flux/
│       └── flux1-dev-fp8.safetensors
├── loras/
│   ├── style/
│   │   └── add_detail.safetensors
│   └── characters/
│       └── kara_v2.safetensors
```

In the ComfyUI dropdown, these appear as `sd15/realisticVision` and `style/add_detail`. Keeps things clean when you have 50+ models.

### What gets symlinked (and why)

On first boot, `start.sh` creates three symlinks:

| Container path | Points to | Purpose |
|---|---|---|
| `/app/ComfyUI/output` | `/storage/output` | Generated images persist across pod restarts |
| `/app/ComfyUI/input` | `/storage/input` | Reference images, masks, and other inputs you upload |
| `/app/ComfyUI/user` | `/storage/user` | ComfyUI settings, saved workflows, and UI preferences |

The script checks if the symlink already exists before creating it. If you're running without a persistent volume (local testing), these directories just stay as regular folders inside the container.

### Storage sizing guide

Plan your persistent volume based on what you'll run:

| Use case | Recommended size |
|---|---|
| SD 1.5 + a few LoRAs | 50 GB |
| SDXL with ControlNets and upscalers | 100 GB |
| Flux + SDXL + video models (HunyuanVideo) | 200-300 GB |
| Everything above + multiple video model variants | 500 GB+ |

Generated output also lands on the volume. A single image is 1-5 MB, but video workflows can produce 100+ MB per generation. Budget extra space if you do video work.

### What happens without a persistent volume

The image still boots and runs. `start.sh` creates `/storage/models/...` directories on the container's ephemeral disk. But everything vanishes when the pod stops. Only useful for quick testing.

## SimplePod Setup

### 1. Create a Persistence Volume

SimplePod dashboard, then Persistence Volumes, then Create:
- **Size**: 200 GB minimum (see sizing guide above)
- **Datacenter**: EU-PL-01 (must match your instances)

### 2. Create a Template

Templates, then Create Custom Template:

| Field | Value |
|---|---|
| **Image Name** | `igork2580/comfyui-5090` |
| **Image Tag** | `latest` |
| **System disk** | 40 GB |
| **Persistence Volume** | Select the volume you created |
| **Mount Point** | `/storage` |
| **Expose Ports** | `8188, 8888, 22` |

The mount point **must** be `/storage`. That's what `extra_model_paths.yaml` and `start.sh` expect.

### 3. Launch an instance

Select your template, pick an RTX 5090 GPU, and start. On first boot, `start.sh`:
1. Creates all model subdirectories inside `/storage/models/`
2. Symlinks output, input, and user directories
3. Prints PyTorch and CUDA versions to the log
4. Hands off to Supervisor, which starts ComfyUI, JupyterLab, and SSH

### 4. Upload your models

Three ways to get models onto the persistent volume:

**JupyterLab (port 8888):** Browser-based file manager. Navigate to `/storage/models/checkpoints/` and drag-and-drop files. Good for files under ~2 GB.

**SSH/SCP:** Best for large files or batch uploads.
```bash
# From your local machine
scp -P <ssh_port> my_checkpoint.safetensors root@<pod_ip>:/storage/models/checkpoints/

# From inside the pod, download directly
cd /storage/models/checkpoints
wget https://huggingface.co/author/model/resolve/main/model.safetensors
```

**comfy-cli (from inside the pod):** Works for models hosted on CivitAI or HuggingFace registries.
```bash
comfy model download --url https://civitai.com/models/12345
```

### 5. Open ComfyUI

Navigate to port 8188 in your browser. Models appear in dropdown menus automatically.

## Migrating from existing setup

If you have models on an existing SimplePod volume mounted at `/app`:

```bash
# SSH into a pod with both volumes accessible
# Copy everything to the new structure
rsync -av /app/ComfyUI/models/ /storage/models/

# Or if volumes are on different pods, use scp between them
```

## Ports

| Port | Service | Purpose |
|---|---|---|
| 8188 | ComfyUI | Main UI + API |
| 8888 | JupyterLab | File manager, model uploads, output browsing |
| 22 | SSH | Remote access, scripting, SCP file transfers |

## Why not xformers?

On RTX 5090 (Blackwell), xformers causes three problems:
1. **Silently downgrades PyTorch** from cu130 to cu128 via its dependency chain, which breaks NVFP4
2. **Has no prebuilt wheels** for sm_120 and must build from source
3. **Is slower** than PyTorch SDPA + SageAttention on Blackwell

Benchmarks: xformers 5.194ms vs SDPA 5.049ms vs SageAttention 2.671ms.

The image uses PyTorch's built-in SDPA as default, with SageAttention available for an additional ~2x speedup on attention operations.

## Build notes

The Dockerfile uses `nvidia/cuda:13.0.1-devel-ubuntu22.04` as the base. The `devel` variant is ~3.5 GB larger than `runtime`, but it includes gcc, nvcc, and CUDA headers needed to compile SageAttention's CUDA kernels and any custom node C extensions. A multi-stage build could slim this down later.

Ubuntu 22.04 ships Python 3.10, so the Dockerfile adds the [deadsnakes PPA](https://launchpad.net/~deadsnakes/+archive/ubuntu/ppa) for Python 3.12. pip is installed via `get-pip.py` (the apt `python3-pip` package targets the system Python 3.10).

## Updating custom nodes

**Update a git-cloned node:** Change its commit hash in the Dockerfile and rebuild.

**Add a new CNR node:** Add it to the `comfy node install` list in the Dockerfile.

**Add a new git node:**
```dockerfile
RUN git clone https://github.com/author/ComfyUI-NewNode.git && \
    cd ComfyUI-NewNode && git checkout <commit_hash> && cd ..
```

Push to trigger a rebuild via GitHub Actions.

## Building locally

```bash
docker build -t igork2580/comfyui-5090:latest .
docker push igork2580/comfyui-5090:latest
```

## License

MIT
