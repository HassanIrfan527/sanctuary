#!/usr/bin/env bash
# Clipboard history picker — cliphist piped through fzf in a floating kitty.
# A real window, so niri animates it like everything else.
set -uo pipefail
command -v cliphist >/dev/null 2>&1 || exit 0

# The clear-all row. It is a real selectable entry rather than a keybind-only
# action for the same reason the notification centre has a `[ clear all ]`
# button next to its keybind (DESIGN-BRIEF.md §1): an affordance you cannot
# see is one you cannot press.
#
# Deliberately NOT styled with ANSI colour, which would mean passing --ansi to
# fzf — and every other row here is arbitrary clipboard content. Letting fzf
# interpret escape sequences in text you copied off the internet is a way to
# get a mangled list at best. The brackets carry the affordance instead.
CLEAR='[ clear all ]'
feed() { printf '%s\n' "$CLEAR"; cliphist list; }
export -f feed
export CLEAR

sel=$(feed | fzf \
  --no-sort --reverse --border=sharp \
  --border-label=' clipboard ' --border-label-pos=2 \
  --prompt='[ paste ] ' --pointer='▸' --info=inline-right \
  --color='bg+:#1e1e2e,fg:#a6adc8,fg+:#cdd6f4,hl:#cba6f7,hl+:#cba6f7' \
  --color='border:#797faa,label:#b4befe,info:#45475a' \
  --color='prompt:#b4befe,pointer:#b4befe,spinner:#585b70' \
  --bind 'ctrl-j:down,ctrl-k:up' \
  --bind 'load:down' \
  --bind 'ctrl-x:execute-silent(cliphist delete <<< {})+reload(bash -c feed)')

[ -n "$sel" ] || exit 0

# `load:down` moves the cursor off the clear row before you can touch it, so
# the default Enter still pastes the newest entry. It has to be `load`, not
# `start`: `start` fires before the item list exists, so the cursor move was
# silently lost and the pointer sat on `[ clear all ]` at open. cliphist wipe is not
# reversible and there is no confirmation prompt on purpose — §1 says nothing
# regularly touched may require navigating, and clipboard history rebuilds
# itself. Being one row out of reach is the whole safety margin.
if [ "$sel" = "$CLEAR" ]; then
  cliphist wipe
  exit 0
fi

# `setsid` is load-bearing. wl-copy MUST stay resident — it owns the Wayland
# selection until something replaces it — and while it holds kitty's pty the
# picker window never closes. setsid moves it into its own session so the
# terminal can exit while the clipboard keeps working.
cliphist decode <<< "$sel" | setsid wl-copy >/dev/null 2>&1
