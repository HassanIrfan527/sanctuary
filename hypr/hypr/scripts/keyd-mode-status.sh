#!/usr/bin/env bash
# keyd-mode-status.sh — bottom-bar mode block (left cap).
# PASSTHROUGH (default) vs keyd NAVIGATION layer. State file set by keyd-mode.sh.

if [ -e /tmp/keyd-mode-nav ]; then
    printf '{"text":"NAV","class":"navigation","alt":"navigation"}\n'
else
    printf '{"text":"NORM","class":"passthrough","alt":"passthrough"}\n'
fi
