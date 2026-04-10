#!/bin/bash
export GI_TYPELIB_PATH="/usr/local/lib64/girepository-1.0:$GI_TYPELIB_PATH"
{
    echo "=== ags-run.sh started at $(date) ==="
    echo "PATH=$PATH"
    echo "WAYLAND_DISPLAY=$WAYLAND_DISPLAY"
    echo "XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR"
    echo "HOME=$HOME"
    echo "USER=$USER"
    echo "GI_TYPELIB_PATH=$GI_TYPELIB_PATH"
    echo "--- running ags ---"
} > /tmp/ags.log 2>&1
exec /usr/local/bin/ags run >> /tmp/ags.log 2>&1
