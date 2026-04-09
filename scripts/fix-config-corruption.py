#!/usr/bin/env python3
"""
Fix quickshell config corruption caused by power outage.
Strings get serialized as character arrays, e.g. "hello" -> ["h","e","l","l","o"].
Empty strings become empty arrays [].
This script joins char arrays back into strings and fixes empty arrays
for known string fields.

Can be passed specific file paths, or defaults to the standard locations.
"""
import json
import os
import sys
from pathlib import Path

DEFAULT_FILES = [
    Path.home() / ".config/illogical-impulse/config.json",
    Path.home() / ".local/state/quickshell/states.json",
]


def is_char_array(obj):
    return (
        isinstance(obj, list)
        and len(obj) > 0
        and all(isinstance(x, str) and len(x) == 1 for x in obj)
    )


def is_corrupted(obj):
    if isinstance(obj, dict):
        return any(is_corrupted(v) for v in obj.values())
    elif isinstance(obj, list):
        if is_char_array(obj):
            return True
        return any(is_corrupted(v) for v in obj)
    return False


def fix_value(obj):
    if isinstance(obj, dict):
        return {k: fix_value(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        if is_char_array(obj):
            return "".join(obj)
        return [fix_value(item) for item in obj]
    return obj


def fix_empty_arrays_to_strings(obj, schema=None):
    """Fix empty arrays that should be empty strings.
    Uses a simple heuristic: if the key name suggests a string type
    (path, name, text, color, etc.), convert [] to ""."""
    string_hints = {
        "wallpaperPath", "thumbnailPath", "accentColor", "text", "city",
        "savePath", "theme", "layout", "style", "family", "format",
        "engine", "locale", "model", "provider", "username",
        "hyprlandInstanceSignature",
    }
    if isinstance(obj, dict):
        result = {}
        for k, v in obj.items():
            if isinstance(v, list) and len(v) == 0 and k in string_hints:
                result[k] = ""
            else:
                result[k] = fix_empty_arrays_to_strings(v)
        return result
    elif isinstance(obj, list):
        return [fix_empty_arrays_to_strings(item) for item in obj]
    return obj


def fix_file(path):
    if not path.exists():
        return

    with open(path) as f:
        try:
            data = json.load(f)
        except json.JSONDecodeError:
            print(f"SKIP (invalid JSON): {path}")
            return

    if not is_corrupted(data):
        print(f"OK: {path}")
        return

    fixed = fix_value(data)
    fixed = fix_empty_arrays_to_strings(fixed)

    temp_path = path.with_suffix(".json.fixed")
    with open(temp_path, "w") as f:
        json.dump(fixed, f, indent=2, ensure_ascii=True)

    temp_path.rename(path)
    print(f"FIXED: {path}")


def main():
    files = [Path(p) for p in sys.argv[1:]] if len(sys.argv) > 1 else DEFAULT_FILES
    for f in files:
        fix_file(f)


if __name__ == "__main__":
    main()
