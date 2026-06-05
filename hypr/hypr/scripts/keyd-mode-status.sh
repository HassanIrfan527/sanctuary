#!/usr/bin/env bash
# keyd-mode-status.sh — bottom-bar mode block (left cap).
# PASSTHROUGH (default) vs keyd NAVIGATION layer. State file set by keyd-mode.sh.

if [ -e /tmp/keyd-mode-nav ]; then
    printf '{"text":"NAVIGATION","class":"navigation","alt":"navigation"}\n'
else
    printf '{"text":"NORMAL","class":"passthrough","alt":"passthrough"}\n'
fi
