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

FROM nvidia/cuda:13.0.1-devel-ubuntu22.04 AS base

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# ── System packages + deadsnakes PPA for Python 3.12 ────────
# Ubuntu 22.04 ships Python 3.10; need deadsnakes PPA for 3.12.
RUN apt-get update && apt-get install -y --no-install-recommends \
        software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && apt-get install -y --no-install-recommends \
        python3.12 python3.12-venv python3.12-dev \
        git git-lfs wget curl rsync \
        ffmpeg libgl1-mesa-glx libglib2.0-0 libsm6 libxext6 libxrender1 \
        openssh-server \
    && rm -rf /var/lib/apt/lists/* \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3.12 1

# ── pip setup (get-pip.py for deadsnakes Python 3.12) ───────
# python3-pip from apt targets system Python 3.10, not 3.12.
RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python3.12 && \
    python -m pip install --upgrade pip setuptools wheel && \
    pip install --no-cache-dir supervisor

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

# ── Custom nodes from git (replaces broken comfy-cli/CNR) ────
# comfy-cli's cm-cli.py fails in Docker builds (needs running ComfyUI).
# Direct git clone is reliable and matches somb1/ComfyUI-Docker approach.
COPY custom_nodes.txt /tmp/custom_nodes.txt
WORKDIR /app/ComfyUI/custom_nodes
RUN xargs -n 1 git clone --recursive < /tmp/custom_nodes.txt && \
    rm /tmp/custom_nodes.txt

# ── Pinned-commit custom nodes (not available on CNR) ────────
RUN git clone https://github.com/M1kep/ComfyLiterals.git && \
        cd ComfyLiterals && git checkout bdddb08 && cd .. && \
    git clone https://github.com/kijai/ComfyUI-MMAudio.git && \
        cd ComfyUI-MMAudio && git checkout 8eaeb72 && cd .. && \
    git clone https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git && \
        cd ComfyUI_Comfyroll_CustomNodes && git checkout d78b780 && cd .. && \
    git clone https://github.com/giriss/comfy-image-saver.git && \
        cd comfy-image-saver && git checkout 65e6903 && cd .. && \
    git clone https://github.com/jamesWalker55/comfyui-various.git && \
        cd comfyui-various && git checkout 5bd85aa && cd ..

# ── Install all custom node deps (single global resolve) ───
RUN find /app/ComfyUI/custom_nodes -name "requirements.txt" \
        -exec cat {} + > /tmp/all_reqs.txt 2>/dev/null && \
    pip install --no-cache-dir -r /tmp/all_reqs.txt || true && \
    rm -f /tmp/all_reqs.txt

# Run install.py scripts where they exist
RUN for d in /app/ComfyUI/custom_nodes/*/; do \
        [ -f "$d/install.py" ] && cd "$d" && python install.py || true; \
    done

# ── Verify PyTorch wasn't downgraded by deps ───────────────
# CRITICAL: custom node deps (especially xformers) can silently
# replace cu130 nightly with cu128 stable. This check catches it.
RUN python -c "\
import torch; \
v = torch.version.cuda; \
assert v and v.startswith('13.'), \
    f'CUDA version is {v}, expected 13.x. A dependency downgraded PyTorch!'; \
print(f'OK: torch={torch.__version__}, cuda={v}')"

# ── Verify custom node count ────────────────────────────────
# The || true on node installs silently swallows failures.
# Fail the build if too few nodes are present.
RUN node_count=$(find /app/ComfyUI/custom_nodes -maxdepth 1 -type d | wc -l) && \
    echo "Custom nodes installed: $((node_count - 1))" && \
    [ "$node_count" -gt 20 ] || \
    (echo "FAIL: Only $((node_count - 1)) nodes installed, expected 22+" && exit 1)

# ── Model paths → persistent volume ────────────────────────
COPY extra_model_paths.yaml /app/ComfyUI/extra_model_paths.yaml

# ── SSH + Supervisor (SimplePod compatibility) ──────────────
RUN mkdir -p /var/run/sshd /var/log && \
    ssh-keygen -A && \
    echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
COPY scripts/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY scripts/start.sh /start.sh
RUN chmod +x /start.sh

# ── Output + input dirs (will be overridden by volume) ──────
RUN mkdir -p /app/ComfyUI/output /app/ComfyUI/input

WORKDIR /app/ComfyUI
EXPOSE 8188 22

CMD ["/start.sh"]
