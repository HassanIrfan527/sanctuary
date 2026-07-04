#!/usr/bin/env bash
# keyd-mode-status.sh — bottom-bar mode block (right cap of the right capsule).
# Reflects the active keyd layer(s). State files set by keyd-mode.sh (NAVIGATION)
# and keyd-arrows.sh (ARROWS); both poke this module via RTMIN+9.

nav=0; arw=0
[ -e /tmp/keyd-mode-nav ]    && nav=1
[ -e /tmp/keyd-mode-arrows ] && arw=1

if [ "$nav" = 1 ] && [ "$arw" = 1 ]; then
    printf '{"text":"NAV+ARROWS","class":"arrows","alt":"arrows"}\n'
elif [ "$arw" = 1 ]; then
    printf '{"text":"ARROWS","class":"arrows","alt":"arrows"}\n'
elif [ "$nav" = 1 ]; then
    printf '{"text":"NAVIGATION","class":"navigation","alt":"navigation"}\n'
else
    printf '{"text":"NORMAL","class":"passthrough","alt":"passthrough"}\n'
fi
