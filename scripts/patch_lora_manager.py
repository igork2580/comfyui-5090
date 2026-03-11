"""Patch LoRA-Manager folder_paths fallback on cache miss.

When scanner cache is empty (fresh pod), get_lora_info() and
get_lora_info_absolute() return bare filename instead of resolved
path -> FileNotFoundError. This adds a folder_paths.get_full_path()
fallback before each function's 'return lora_name, []'.

Uses function-targeted insertion (finds each def, then patches within
that function's scope) instead of fragile code.replace().
"""

import os

path = '/ComfyUI/custom_nodes/ComfyUI-Lora-Manager/py/utils/utils.py'
with open(path) as f:
    lines = f.readlines()

# The marker line we're looking for inside each function
MARKER = '        return lora_name, []\n'

# Fallback for get_lora_info (returns relative paths)
rel_fallback = """\
        # Cache miss - fall back to ComfyUI folder_paths
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
"""

# Fallback for get_lora_info_absolute (returns absolute paths)
abs_fallback = """\
        # Cache miss - fall back to ComfyUI folder_paths
        import folder_paths as _fp
        candidates = (lora_name,) if lora_name.endswith('.safetensors') else (lora_name, lora_name + '.safetensors')
        for candidate in candidates:
            full = _fp.get_full_path('loras', candidate)
            if full:
                return full, []
"""


def find_function_start(lines, func_name):
    """Find the line index where a function is defined."""
    for i, line in enumerate(lines):
        if line.strip().startswith(f'def {func_name}(') or \
           line.strip().startswith(f'async def {func_name}('):
            return i
    return None


def find_marker_in_function(lines, func_start):
    """Find the first 'return lora_name, []' within the function scope."""
    for i in range(func_start + 1, len(lines)):
        # Stop if we hit the next top-level or class-level definition
        if lines[i].strip() and not lines[i].startswith(' ') and not lines[i].startswith('\t'):
            break
        if lines[i] == MARKER:
            return i
    return None


# Find each function and its marker
get_lora_info_start = find_function_start(lines, 'get_lora_info')
get_lora_info_abs_start = find_function_start(lines, 'get_lora_info_absolute')

if get_lora_info_start is None:
    raise RuntimeError("Could not find 'def get_lora_info(' in utils.py")
if get_lora_info_abs_start is None:
    raise RuntimeError("Could not find 'def get_lora_info_absolute(' in utils.py")

rel_marker = find_marker_in_function(lines, get_lora_info_start)
abs_marker = find_marker_in_function(lines, get_lora_info_abs_start)

if rel_marker is None:
    raise RuntimeError("Could not find 'return lora_name, []' in get_lora_info()")
if abs_marker is None:
    raise RuntimeError("Could not find 'return lora_name, []' in get_lora_info_absolute()")

# Insert fallbacks before each marker (process from bottom up to preserve indices)
patches = sorted([(rel_marker, rel_fallback), (abs_marker, abs_fallback)],
                 key=lambda x: x[0], reverse=True)

for marker_idx, fallback in patches:
    lines.insert(marker_idx, fallback)

with open(path, 'w') as f:
    f.writelines(lines)

print('LoRA-Manager patched: get_lora_info + get_lora_info_absolute')
