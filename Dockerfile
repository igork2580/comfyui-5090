# ============================================================
# ComfyUI RTX 5090 (Blackwell) — Pre-built Base Image
# ============================================================
# Based on somb1's tested image with CUDA 12.8, Python 3.13,
# PyTorch 2.8.0 stable, ComfyUI, Manager, and 23 custom nodes.
# We layer Igor's extra nodes + SimplePod config on top.
#
# Stack: CUDA 12.8 | Python 3.13 | PyTorch 2.8.0 stable
# ============================================================

FROM sombi/comfyui:base-torch2.8.0-cu128

# ── Symlink for gen-studio compatibility ─────────────────────
# gen-studio hardcodes /app/ComfyUI in pod manager + node resolver.
RUN mkdir -p /app && ln -s /ComfyUI /app/ComfyUI

# ── Make venv python available system-wide ───────────────────
# SSH sessions don't inherit Docker ENV PATH, so symlink python/pip.
RUN ln -sf /venv/bin/python /usr/local/bin/python && \
    ln -sf /venv/bin/pip /usr/local/bin/pip

# ── SageAttention (CUDA backend, ~2x faster than SDPA) ──────
RUN pip install --no-cache-dir sageattention || true

# ── Extra custom nodes (ones NOT in base image) ─────────────
COPY custom_nodes.txt /tmp/custom_nodes.txt
WORKDIR /ComfyUI/custom_nodes
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

# ── Install deps for extra nodes only ────────────────────────
RUN for req in /ComfyUI/custom_nodes/*/requirements.txt; do \
        pip install --no-cache-dir -r "$req" || true; \
    done
RUN for d in /ComfyUI/custom_nodes/*/; do \
        [ -f "$d/install.py" ] && cd "$d" && python install.py || true; \
    done

# ── Patch VHS helpDOM bug (crashes workflow loading) ─────────
RUN sed -i 's/helpDOM.addHelp(this, nodeType, description)/if (helpDOM \&\& helpDOM.addHelp) { helpDOM.addHelp(this, nodeType, description) }/' \
    /ComfyUI/custom_nodes/ComfyUI-VideoHelperSuite/web/js/VHS.core.js || true

# ── Patch ComfyUI utils.py TypeError on FileNotFoundError ────
# e.args[0] can be an int (errno), not a string. Cast to str.
RUN sed -i 's/message = e.args\[0\]/message = str(e.args[0])/' \
    /ComfyUI/comfy/utils.py

# ── Patch LoRA-Manager: folder_paths fallback on cache miss ──
# When scanner cache is empty (fresh pod), get_lora_info_absolute()
# returns bare filename instead of absolute path → FileNotFoundError.
# This adds a folder_paths.get_full_path() fallback before returning.
COPY scripts/patch_lora_manager.py /tmp/patch_lora_manager.py
RUN python /tmp/patch_lora_manager.py && rm /tmp/patch_lora_manager.py

# ── Verify PyTorch wasn't downgraded by deps ─────────────────
RUN python -c "import torch; v=torch.version.cuda; assert v.startswith('12.8'), f'CUDA {v}, expected 12.8'"

# ── Verify custom node count ────────────────────────────────
RUN node_count=$(find /ComfyUI/custom_nodes -maxdepth 1 -type d | wc -l) && \
    echo "Custom nodes installed: $((node_count - 1))" && \
    [ "$node_count" -gt 60 ] || \
    (echo "FAIL: Only $((node_count - 1)) nodes installed, expected 60+" && exit 1)

# ── Model paths → persistent volume ─────────────────────────
COPY extra_model_paths.yaml /ComfyUI/extra_model_paths.yaml

# ── Supervisor (SimplePod compatibility) ──────────────────────
# Base image already has openssh-server + PermitRootLogin.
# We add supervisor to manage ComfyUI + sshd together.
RUN apt-get update && apt-get install -y --no-install-recommends supervisor && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /var/run/sshd /var/log
COPY scripts/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY scripts/start.sh /start.sh
RUN chmod +x /start.sh

# ── Output + input dirs (ephemeral) ─────────────────────────
RUN mkdir -p /ComfyUI/output /ComfyUI/input

WORKDIR /ComfyUI
EXPOSE 8188 22

CMD ["/start.sh"]
