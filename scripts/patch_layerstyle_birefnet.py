#!/usr/bin/env python3
"""Patch ComfyUI_LayerStyle_Advance's birefnet_ultra_v2.py for the torch-2.8 /
Python-3.13 stack.

Two problems on this stack:
  1. `LoadBiRefNetModelV2` with version="BiRefNet-General": if the legacy .pth
     isn't present, the if/elif logic falls straight through to
     `from_pretrained(model_path, ...)` WITHOUT ever downloading — and the model
     loads with mixed fp16/fp32 weights, so `BiRefNetUltraV2` then dies with
     "Input type (float) and bias type (c10::Half) should be the same".
     (The model files themselves are pre-placed at
     /storage/models/BiRefNet/BiRefNet-General/ by start.sh.)
  2. Fix: force the loaded model AND the inference input to float32.
"""
import sys, os

F = "/ComfyUI/custom_nodes/ComfyUI_LayerStyle_Advance/py/birefnet_ultra_v2.py"
if not os.path.exists(F):
    print(f"[patch_layerstyle_birefnet] {F} not found — skipping")
    sys.exit(0)

src = open(F).read()
PATCHES = [
    # load the HF model in fp32 (and re-cast for good measure)
    ("AutoModelForImageSegmentation.from_pretrained(model_path, trust_remote_code=True)",
     "AutoModelForImageSegmentation.from_pretrained(model_path, trust_remote_code=True, torch_dtype=torch.float32).float()"),
    # belt-and-suspenders: re-cast the model to fp32 right before inference
    ("        birefnet_model.eval()",
     "        birefnet_model.eval()\n        try:\n            birefnet_model.float()\n        except Exception:\n            pass"),
    # make the input image fp32 so it matches
    ("inference_image = transform_image(orig_image).unsqueeze(0).to(device)",
     "inference_image = transform_image(orig_image).unsqueeze(0).to(device).float()"),
]
applied = 0
for old, new in PATCHES:
    if new in src:
        continue  # already patched
    if old in src:
        src = src.replace(old, new, 1)
        applied += 1
    else:
        print(f"[patch_layerstyle_birefnet] anchor not found (skipped): {old[:70]}...")
open(F, "w").write(src)
print(f"[patch_layerstyle_birefnet] applied {applied} patch(es) to birefnet_ultra_v2.py")
