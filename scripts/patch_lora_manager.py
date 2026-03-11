"""Patch LoRA-Manager folder_paths fallback on cache miss.

When scanner cache is empty (fresh pod), get_lora_info_absolute()
returns bare filename instead of absolute path -> FileNotFoundError.
This adds a folder_paths.get_full_path() fallback before returning.
"""

import re
import os

path = '/ComfyUI/custom_nodes/ComfyUI-Lora-Manager/py/utils/utils.py'
with open(path) as f:
    code = f.read()

# Fallback block for absolute path function
abs_fallback = '''        # Cache miss - fall back to ComfyUI folder_paths
        import folder_paths as _fp
        candidates = (lora_name,) if lora_name.endswith('.safetensors') else (lora_name, lora_name + '.safetensors')
        for candidate in candidates:
            full = _fp.get_full_path('loras', candidate)
            if full:
                return full, []
        return lora_name, []'''

# Fallback block for relative path function
rel_fallback = '''        # Cache miss - fall back to ComfyUI folder_paths
        import folder_paths as _fp
        candidates = (lora_name,) if lora_name.endswith('.safetensors') else (lora_name, lora_name + '.safetensors')
        for candidate in candidates:
            full = _fp.get_full_path('loras', candidate)
            if full:
                for root in config.loras_roots:
                    root = root.replace(os.sep, '/')
                    if full.startswith(root):
                        return os.path.relpath(full, root).replace(os.sep, '/'), []
                return candidate, []
        return lora_name, []'''

# Replace both 'return lora_name, []' lines (inside async functions only)
# Pattern: the bare return right before the try/except block
code = code.replace(
    '        return lora_name, []\n    \n    try:\n        # Check if we',
    abs_fallback + '\n    \n    try:\n        # Check if we',
    1  # Replace second occurrence (absolute version)
)
# The first occurrence is in get_lora_info (relative version)
code = code.replace(
    '        return lora_name, []\n    \n    try:\n        # Check if we',
    rel_fallback + '\n    \n    try:\n        # Check if we',
    1  # Replace first remaining occurrence
)
with open(path, 'w') as f:
    f.write(code)
print('LoRA-Manager patched')
