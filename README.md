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

- **74 custom nodes** (29 git-cloned + 45 CNR-managed)
- ComfyUI-Manager for easy node management
- SageAttention 2.x for accelerated attention
- SSH + Supervisor for cloud pod management
- `extra_model_paths.yaml` pointing to persistent volume

## Persistent Volume Layout

Mount your persistent volume at `/storage`:

```
/storage/
├── models/
│   ├── checkpoints/
│   ├── loras/
│   ├── vae/
│   ├── controlnet/
│   ├── clip/
│   ├── clip_vision/
│   ├── diffusion_models/
│   ├── embeddings/
│   ├── style_models/
│   ├── text_encoders/
│   ├── unet/
│   └── upscale_models/
├── output/          ← symlinked from /app/ComfyUI/output
├── input/           ← symlinked from /app/ComfyUI/input
└── user/            ← ComfyUI user settings (persisted)
```

## SimplePod Setup

1. Create a Persistence Volume (200GB recommended)
2. Create a template using this image
3. Set mount point to `/storage`
4. Expose port `8188` (ComfyUI) and `22` (SSH)
5. First boot: copy your models to `/storage/models/`

## Build

```bash
docker build -t yourusername/comfyui-5090:latest docker/comfyui-pod/
docker push yourusername/comfyui-5090:latest
```

## Why not xformers?

On RTX 5090 (Blackwell), xformers:
1. Silently downgrades PyTorch from cu130 to cu128 (breaks NVFP4)
2. Has no prebuilt wheels for sm_120
3. Is slower than PyTorch SDPA + SageAttention on Blackwell

Benchmarks: xformers 5.194ms vs SDPA 5.049ms vs SageAttention 2.671ms

## Updating nodes

To update a pinned custom node, change its commit hash in the Dockerfile and rebuild.
To add new CNR nodes, add them to the `comfy node install` list.
