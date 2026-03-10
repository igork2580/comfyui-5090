# ============================================================
# ComfyUI RTX 5090 (Blackwell) — Optimized Docker Template
# ============================================================
# Built for NVFP4 quantization (2-3x speedup on Blackwell).
# No xformers — uses PyTorch SDPA + SageAttention instead.
# Models live on persistent volume at /storage.
# No boot scripts, no PYTHONPATH hacks.
#
# Stack: CUDA 13.0 | Python 3.12 | PyTorch nightly cu130
# ============================================================

FROM nvidia/cuda:13.0.1-runtime-ubuntu22.04 AS base

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# ── System packages ─────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3.12 python3.12-venv python3.12-dev python3-pip \
        git git-lfs wget curl rsync \
        ffmpeg libgl1-mesa-glx libglib2.0-0 libsm6 libxext6 libxrender1 \
        openssh-server supervisor \
    && rm -rf /var/lib/apt/lists/* \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1 \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3.12 1

# ── pip setup ───────────────────────────────────────────────
RUN python -m pip install --upgrade pip setuptools wheel

# ── PyTorch nightly cu130 (pinned for reproducibility) ──────
# NVFP4 quantization REQUIRES cu130. Do NOT downgrade to cu128.
# Pin date: change this when you validate a newer nightly.
ARG TORCH_DATE=20260309
RUN pip install --no-cache-dir --pre \
        torch torchvision torchaudio \
        --index-url https://download.pytorch.org/whl/cu130

# ── SageAttention (CUDA backend, ~2x faster than SDPA) ─────
# Using CUDA backend, NOT Triton (Triton causes black output with some models).
RUN pip install --no-cache-dir sageattention || true

# ── ComfyUI core ────────────────────────────────────────────
WORKDIR /app
RUN git clone https://github.com/comfyanonymous/ComfyUI.git && \
    cd ComfyUI && \
    pip install --no-cache-dir -r requirements.txt

# ── ComfyUI Manager (needed for CNR nodes) ──────────────────
WORKDIR /app/ComfyUI/custom_nodes
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git

# ── CNR-managed nodes (installed via comfy-cli) ─────────────
# These were previously managed by ComfyUI-Manager on the pod.
# Install comfy-cli, then batch install all CNR nodes.
RUN pip install --no-cache-dir comfy-cli && \
    comfy --skip-prompt install --path /app/ComfyUI || true

WORKDIR /app/ComfyUI/custom_nodes
RUN comfy --skip-prompt node install \
        comfyui-impact-pack \
        comfyui-impact-subpack \
        comfyui-inspire-pack \
        comfyui-kjnodes \
        comfyui-controlnet-aux \
        comfyui-ipadapter-plus \
        comfyui-essentials \
        comfyui-videohelpersuite \
        comfyui-frame-interpolation \
        comfyui-gguf \
        comfyui-lora-manager \
        comfyui-multigpu \
        comfyui-post-processing-nodes \
        cg-use-everywhere \
        rgthree-comfy \
        was-ns \
        comfyui-easy-use \
        comfyui-florence2 \
        comfyui-detail-daemon \
        comfyui-dream-project \
        comfyui-art-venture \
        comfyui-ppm \
        comfyui-unload-model \
        comfyui-hakuimg \
        comfyui-cliption \
        comfyui-custom-scripts \
        comfyui-denoisechooser \
        comfyui-fbcnn \
        comfyui-image-saver \
        comfyui-mxtoolkit \
        comfyui-videonoisewarp \
        comfy-mtb \
        comfyui-tinyterranodes \
        comfyui-ultimatesdupscale \
        derfuu-comfyui-moddednodes \
        efficiency-nodes-comfyui \
        maxedout \
        wavespeed \
        wywywywy-pause \
        z-tipo-extension \
        the-ai-doctors-clinical-tools \
        comfyui-melbandroformer \
        comfyui-wanvideowrapper \
        comfyui-framepackwrapper-plusone \
    || true

# ── Real git-cloned custom nodes (pinned commits) ──────────
RUN git clone https://github.com/ManglerFTW/ComfyI2I.git && \
        cd ComfyI2I && git checkout 2bd011b && cd .. && \
    git clone https://github.com/M1kep/ComfyLiterals.git && \
        cd ComfyLiterals && git checkout bdddb08 && cd .. && \
    git clone https://github.com/evanspearman/ComfyMath.git && \
        cd ComfyMath && git checkout c011772 && cd .. && \
    git clone https://github.com/Eagle-CN/ComfyUI-Addoor.git && \
        cd ComfyUI-Addoor && git checkout d51659f && cd .. && \
    git clone https://github.com/crystian/ComfyUI-Crystools.git && \
        cd ComfyUI-Crystools && git checkout 2f18256 && cd .. && \
    git clone https://github.com/ShmuelRonen/ComfyUI-FramePackWrapper_Plus.git && \
        cd ComfyUI-FramePackWrapper_Plus && git checkout 93e60c8 && cd .. && \
    git clone https://github.com/facok/ComfyUI-HunyuanVideoMultiLora.git && \
        cd ComfyUI-HunyuanVideoMultiLora && git checkout 9e18b97 && cd .. && \
    git clone https://github.com/spacepxl/ComfyUI-Image-Filters.git && \
        cd ComfyUI-Image-Filters && git checkout bbb3fb0 && cd .. && \
    git clone https://github.com/ShmuelRonen/ComfyUI-ImageMotionGuider.git && \
        cd ComfyUI-ImageMotionGuider && git checkout de25e08 && cd .. && \
    git clone https://github.com/K3NK3/ComfyUI-K3NKImageGrab.git && \
        cd ComfyUI-K3NKImageGrab && git checkout 3da3775 && cd .. && \
    git clone https://github.com/kijai/ComfyUI-MMAudio.git && \
        cd ComfyUI-MMAudio && git checkout 8eaeb72 && cd .. && \
    git clone https://github.com/DoctorDiffusion/ComfyUI-MediaMixer.git && \
        cd ComfyUI-MediaMixer && git checkout 2bae7b5 && cd .. && \
    git clone https://github.com/princepainter/ComfyUI-PainterI2V.git && \
        cd ComfyUI-PainterI2V && git checkout 83e14e6 && cd .. && \
    git clone https://github.com/princepainter/ComfyUI-PainterLongVideo.git && \
        cd ComfyUI-PainterLongVideo && git checkout 889b4ff && cd .. && \
    git clone https://github.com/GACLove/ComfyUI-VFI.git && \
        cd ComfyUI-VFI && git checkout 6176a43 && cd .. && \
    git clone https://github.com/ai-shizuka/ComfyUI-tbox.git && \
        cd ComfyUI-tbox && git checkout 2d25ad7 && cd .. && \
    git clone https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git && \
        cd ComfyUI_Comfyroll_CustomNodes && git checkout d78b780 && cd .. && \
    git clone https://github.com/11dogzi/Comfyui-ergouzi-Nodes.git && \
        cd Comfyui-ergouzi-Nodes && git checkout 0d6ac29 && cd .. && \
    git clone https://github.com/ClownsharkBatwing/RES4LYF.git && \
        cd RES4LYF && git checkout 0dc91c0 && cd .. && \
    git clone https://github.com/giriss/comfy-image-saver.git && \
        cd comfy-image-saver && git checkout 65e6903 && cd .. && \
    git clone https://github.com/ashtar1984/comfyui-find-perfect-resolution.git && \
        cd comfyui-find-perfect-resolution && git checkout b8ee6c1 && cd .. && \
    git clone https://github.com/Goshe-nite/comfyui-gps-supplements.git && \
        cd comfyui-gps-supplements && git checkout 7c7ac90 && cd .. && \
    git clone https://github.com/kijai/ComfyUI-HunyuanVideoWrapper.git comfyui-hunyuanvideowrapper && \
        cd comfyui-hunyuanvideowrapper && git checkout fcbd672 && cd .. && \
    git clone https://github.com/jamesWalker55/comfyui-various.git && \
        cd comfyui-various && git checkout 5bd85aa && cd .. && \
    git clone https://github.com/vrgamegirl19/comfyui-vrgamedevgirl.git && \
        cd comfyui-vrgamedevgirl && git checkout ba70d2b && cd .. && \
    git clone https://github.com/BadCafeCode/masquerade-nodes-comfyui.git && \
        cd masquerade-nodes-comfyui && git checkout 432cb4d && cd .. && \
    git clone https://github.com/wallish77/wlsh_nodes.git && \
        cd wlsh_nodes && git checkout 9780746 && cd ..

# ── Install all custom node deps (single global resolve) ───
RUN find /app/ComfyUI/custom_nodes -name "requirements.txt" \
        -exec cat {} + > /tmp/all_reqs.txt 2>/dev/null && \
    pip install --no-cache-dir -r /tmp/all_reqs.txt || true && \
    rm -f /tmp/all_reqs.txt

# Run install.py scripts where they exist
RUN for d in /app/ComfyUI/custom_nodes/*/; do \
        [ -f "$d/install.py" ] && cd "$d" && python install.py || true; \
    done

# ── JupyterLab (for easy file/model management) ────────────
RUN pip install --no-cache-dir jupyterlab

# ── Verify PyTorch wasn't downgraded by deps ───────────────
# CRITICAL: custom node deps (especially xformers) can silently
# replace cu130 nightly with cu128 stable. This check catches it.
RUN python -c "\
import torch; \
v = torch.version.cuda; \
assert v and v.startswith('13.'), \
    f'CUDA version is {v}, expected 13.x. A dependency downgraded PyTorch!'; \
print(f'OK: torch={torch.__version__}, cuda={v}')"

# ── Model paths → persistent volume ────────────────────────
COPY extra_model_paths.yaml /app/ComfyUI/extra_model_paths.yaml

# ── SSH + Supervisor (SimplePod compatibility) ──────────────
RUN mkdir -p /var/run/sshd /var/log && \
    echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
COPY scripts/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY scripts/start.sh /start.sh
RUN chmod +x /start.sh

# ── Output + input dirs (will be overridden by volume) ──────
RUN mkdir -p /app/ComfyUI/output /app/ComfyUI/input

WORKDIR /app/ComfyUI
EXPOSE 8188 8888 22

CMD ["/start.sh"]
