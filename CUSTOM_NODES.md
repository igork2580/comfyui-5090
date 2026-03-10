# Custom Nodes Reference

75 custom nodes total. 29 git-cloned with pinned commits, 45 installed via ComfyUI Registry (CNR), plus ComfyUI-Manager.

## Git-cloned nodes (pinned commits)

These are cloned directly from GitHub with a specific commit pinned for reproducibility. To update one, change its commit hash in the Dockerfile and rebuild.

| Node | Commit | Purpose |
|---|---|---|
| [ComfyI2I](https://github.com/ManglerFTW/ComfyI2I) | `2bd011b` | Image-to-image workflows with masks and regions |
| [ComfyLiterals](https://github.com/M1kep/ComfyLiterals) | `bdddb08` | Literal value nodes (string, int, float) for cleaner workflows |
| [ComfyMath](https://github.com/evanspearman/ComfyMath) | `c011772` | Math operations (add, multiply, clamp, etc.) |
| [ComfyUI-Addoor](https://github.com/Eagle-CN/ComfyUI-Addoor) | `d51659f` | Additional utility nodes |
| [ComfyUI-Crystools](https://github.com/crystian/ComfyUI-Crystools) | `2f18256` | System monitor, metadata reader, image comparisons |
| [ComfyUI-FramePackWrapper_Plus](https://github.com/ShmuelRonen/ComfyUI-FramePackWrapper_Plus) | `93e60c8` | FramePack video generation (extended version) |
| [ComfyUI-HunyuanVideoMultiLora](https://github.com/facok/ComfyUI-HunyuanVideoMultiLora) | `9e18b97` | Multiple LoRA support for HunyuanVideo |
| [ComfyUI-Image-Filters](https://github.com/spacepxl/ComfyUI-Image-Filters) | `bbb3fb0` | Sharpen, blur, color adjustments, frequency separation |
| [ComfyUI-ImageMotionGuider](https://github.com/ShmuelRonen/ComfyUI-ImageMotionGuider) | `de25e08` | Motion guidance for video generation |
| [ComfyUI-K3NKImageGrab](https://github.com/K3NK3/ComfyUI-K3NKImageGrab) | `3da3775` | Grab images from URLs or clipboard |
| [ComfyUI-MMAudio](https://github.com/kijai/ComfyUI-MMAudio) | `8eaeb72` | Audio generation from video (MMAudio model). Needs `mmaudio/` models. |
| [ComfyUI-MediaMixer](https://github.com/DoctorDiffusion/ComfyUI-MediaMixer) | `2bae7b5` | Video/audio mixing and editing |
| [ComfyUI-PainterI2V](https://github.com/princepainter/ComfyUI-PainterI2V) | `83e14e6` | Image-to-video with painting-based control |
| [ComfyUI-PainterLongVideo](https://github.com/princepainter/ComfyUI-PainterLongVideo) | `889b4ff` | Long video generation with painting control |
| [ComfyUI-VFI](https://github.com/GACLove/ComfyUI-VFI) | `6176a43` | Video frame interpolation (slow-mo, FPS upscale) |
| [ComfyUI-tbox](https://github.com/ai-shizuka/ComfyUI-tbox) | `2d25ad7` | Text manipulation and processing nodes |
| [ComfyUI_Comfyroll_CustomNodes](https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes) | `d78b780` | Large collection of utility nodes (switches, lists, schedules) |
| [Comfyui-ergouzi-Nodes](https://github.com/11dogzi/Comfyui-ergouzi-Nodes) | `0d6ac29` | Chinese community utility nodes |
| [RES4LYF](https://github.com/ClownsharkBatwing/RES4LYF) | `0dc91c0` | Advanced samplers (RES, DPM++ variants, noise scheduling) |
| [comfy-image-saver](https://github.com/giriss/comfy-image-saver) | `65e6903` | Save images with metadata, custom naming, formats |
| [comfyui-find-perfect-resolution](https://github.com/ashtar1984/comfyui-find-perfect-resolution) | `b8ee6c1` | Calculate optimal resolution for a given aspect ratio |
| [comfyui-gps-supplements](https://github.com/Goshe-nite/comfyui-gps-supplements) | `7c7ac90` | Supplementary utility nodes |
| [comfyui-hunyuanvideowrapper](https://github.com/kijai/ComfyUI-HunyuanVideoWrapper) | `fcbd672` | HunyuanVideo model wrapper (loading, sampling, LoRA) |
| [comfyui-various](https://github.com/jamesWalker55/comfyui-various) | `5bd85aa` | Batch image ops, string manipulation, math |
| [comfyui-vrgamedevgirl](https://github.com/vrgamegirl19/comfyui-vrgamedevgirl) | `ba70d2b` | Utility nodes for VR content workflows |
| [masquerade-nodes-comfyui](https://github.com/BadCafeCode/masquerade-nodes-comfyui) | `432cb4d` | Mask manipulation (combine, blur, threshold, morph) |
| [wlsh_nodes](https://github.com/wallish77/wlsh_nodes) | `9780746` | Image resizing, outpainting, CLIP text encode shortcuts |

## CNR-managed nodes (via comfy-cli)

Installed from the [ComfyUI Registry](https://registry.comfy.org). Version is determined at build time (latest). To pin a version, use `comfy node install package@version` in the Dockerfile.

| Registry ID | Purpose |
|---|---|
| [comfyui-impact-pack](https://registry.comfy.org/nodes/comfyui-impact-pack) | Face detection/fix, SAM segmentation, detailers. Needs `sams/`, `ultralytics/` models. |
| [comfyui-impact-subpack](https://registry.comfy.org/nodes/comfyui-impact-subpack) | Additional detectors for Impact Pack |
| [comfyui-inspire-pack](https://registry.comfy.org/nodes/comfyui-inspire-pack) | Regional prompting, lora block weight, wildcards |
| [comfyui-kjnodes](https://registry.comfy.org/nodes/comfyui-kjnodes) | Batch processing, scheduling, get/set nodes, string ops |
| [comfyui-controlnet-aux](https://registry.comfy.org/nodes/comfyui-controlnet-aux) | ControlNet preprocessors (OpenPose, depth, canny, etc.) |
| [comfyui-ipadapter-plus](https://registry.comfy.org/nodes/comfyui-ipadapter-plus) | IP-Adapter face/style transfer. Needs `clip_vision/` models. |
| [comfyui-essentials](https://registry.comfy.org/nodes/comfyui-essentials) | Image batch, masks, math, sampling utilities |
| [comfyui-videohelpersuite](https://registry.comfy.org/nodes/comfyui-videohelpersuite) | Video loading, splitting, combining, format conversion |
| [comfyui-frame-interpolation](https://registry.comfy.org/nodes/comfyui-frame-interpolation) | RIFE/FILM frame interpolation for smooth video |
| [comfyui-gguf](https://registry.comfy.org/nodes/comfyui-gguf) | Load GGUF quantized models (smaller, slower) |
| [comfyui-lora-manager](https://registry.comfy.org/nodes/comfyui-lora-manager) | Browse, search, preview LoRAs in the UI |
| [comfyui-multigpu](https://registry.comfy.org/nodes/comfyui-multigpu) | Distribute model components across multiple GPUs |
| [comfyui-post-processing-nodes](https://registry.comfy.org/nodes/comfyui-post-processing-nodes) | Color grading, film grain, vignette, chromatic aberration |
| [cg-use-everywhere](https://registry.comfy.org/nodes/cg-use-everywhere) | Broadcast values to matching inputs without wires |
| [rgthree-comfy](https://registry.comfy.org/nodes/rgthree-comfy) | Power Prompt, context nodes, mute/bypass shortcuts |
| [was-ns](https://registry.comfy.org/nodes/was-ns) | 200+ nodes: image processing, text, masks, debugging |
| [comfyui-easy-use](https://registry.comfy.org/nodes/comfyui-easy-use) | Simplified all-in-one nodes for common pipelines |
| [comfyui-florence2](https://registry.comfy.org/nodes/comfyui-florence2) | Florence-2 vision model (captioning, detection, OCR) |
| [comfyui-detail-daemon](https://registry.comfy.org/nodes/comfyui-detail-daemon) | Detail enhancement during sampling (inject high-freq noise) |
| [comfyui-dream-project](https://registry.comfy.org/nodes/comfyui-dream-project) | Animation, color math, file handling utilities |
| [comfyui-art-venture](https://registry.comfy.org/nodes/comfyui-art-venture) | Checkpoint merging, aspect ratio, IP-Adapter utils |
| [comfyui-ppm](https://registry.comfy.org/nodes/comfyui-ppm) | Perturbed-Attention Guidance (PAG) for sharper images |
| [comfyui-unload-model](https://registry.comfy.org/nodes/comfyui-unload-model) | Force unload models from VRAM |
| [comfyui-hakuimg](https://registry.comfy.org/nodes/comfyui-hakuimg) | Image layering and compositing tools |
| [comfyui-cliption](https://registry.comfy.org/nodes/comfyui-cliption) | CLIP-based image captioning |
| [comfyui-custom-scripts](https://registry.comfy.org/nodes/comfyui-custom-scripts) | Auto-complete, image feed, favorites, workflow helpers |
| [comfyui-denoisechooser](https://registry.comfy.org/nodes/comfyui-denoisechooser) | Preview different denoise levels side by side |
| [comfyui-fbcnn](https://registry.comfy.org/nodes/comfyui-fbcnn) | JPEG artifact removal. Needs `FBCNN/` model. |
| [comfyui-image-saver](https://registry.comfy.org/nodes/comfyui-image-saver) | Save images with custom paths, naming, metadata |
| [comfyui-mxtoolkit](https://registry.comfy.org/nodes/comfyui-mxtoolkit) | Prompt scheduling, image grid, batch utilities |
| [comfyui-videonoisewarp](https://registry.comfy.org/nodes/comfyui-videonoisewarp) | Optical flow-based noise warping for video consistency |
| [comfy-mtb](https://registry.comfy.org/nodes/comfy-mtb) | Face swap, QR codes, animation, color tools |
| [comfyui-tinyterranodes](https://registry.comfy.org/nodes/comfyui-tinyterranodes) | Pipes, full pipelines, xyPlot, text tools |
| [comfyui-ultimatesdupscale](https://registry.comfy.org/nodes/comfyui-ultimatesdupscale) | Tiled upscale with SD (handles any resolution) |
| [derfuu-comfyui-moddednodes](https://registry.comfy.org/nodes/derfuu-comfyui-moddednodes) | Math, tuple operations, text manipulation |
| [efficiency-nodes-comfyui](https://registry.comfy.org/nodes/efficiency-nodes-comfyui) | All-in-one KSampler, XY plot, batch processing |
| [maxedout](https://registry.comfy.org/nodes/maxedout) | Memory optimization and model management |
| [wavespeed](https://registry.comfy.org/nodes/wavespeed) | First-block cache, TeaCache for faster inference |
| [wywywywy-pause](https://registry.comfy.org/nodes/wywywywy-pause) | Pause/resume workflow execution at any point |
| [z-tipo-extension](https://registry.comfy.org/nodes/z-tipo-extension) | Tag-based prompt generation and expansion |
| [the-ai-doctors-clinical-tools](https://registry.comfy.org/nodes/the-ai-doctors-clinical-tools) | Prompt builder, model selector, workflow utilities |
| [comfyui-melbandroformer](https://registry.comfy.org/nodes/comfyui-melbandroformer) | Audio source separation (vocals, drums, bass) |
| [comfyui-wanvideowrapper](https://registry.comfy.org/nodes/comfyui-wanvideowrapper) | Wan2.1 video model wrapper (T2V, I2V) |
| [comfyui-framepackwrapper-plusone](https://registry.comfy.org/nodes/comfyui-framepackwrapper-plusone) | FramePack video generation (community fork) |

## Core

| Node | Source |
|---|---|
| [ComfyUI-Manager](https://github.com/ltdrdata/ComfyUI-Manager) | Git (latest) | Node browser, installer, updater. Required for CNR nodes to work. |

## Model dependencies

Some nodes need specific model files on the persistent volume:

| Node | Model directory | What to download |
|---|---|---|
| comfyui-impact-pack | `sams/`, `ultralytics/` | SAM model + YOLO detection model |
| comfyui-ipadapter-plus | `clip_vision/` | CLIP-ViT-H or CLIP-ViT-bigG |
| comfyui-fbcnn | `FBCNN/` | FBCNN JPEG artifact removal model |
| ComfyUI-MMAudio | `mmaudio/` | MMAudio weights (~8.6 GB) |
| comfyui-controlnet-aux | Downloads automatically | Preprocessor models cached at runtime |
| comfy-mtb | `rembg/` | Background removal model |
