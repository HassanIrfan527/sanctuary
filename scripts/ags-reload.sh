#!/bin/bash
export GI_TYPELIB_PATH="/usr/local/lib64/girepository-1.0:$GI_TYPELIB_PATH"
/usr/local/bin/ags quit 2>/dev/null
sleep 0.5
exec /usr/local/bin/ags run > /tmp/ags.log 2>&1
