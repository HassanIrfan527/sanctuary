#!/usr/bin/env bash
# Clipboard history picker — cliphist piped through fzf in a floating kitty.
# A real window, so niri animates it like everything else.
set -uo pipefail
command -v cliphist >/dev/null 2>&1 || exit 0

sel=$(cliphist list | fzf \
  --no-sort --reverse --border=sharp \
  --border-label=' clipboard ' --border-label-pos=2 \
  --prompt='[ paste ] ' --pointer='▸' --info=inline-right \
  --color='bg+:#1e1e2e,fg:#a6adc8,fg+:#cdd6f4,hl:#cba6f7,hl+:#cba6f7' \
  --color='border:#797faa,label:#b4befe,info:#45475a' \
  --color='prompt:#b4befe,pointer:#b4befe,spinner:#585b70' \
  --bind 'ctrl-j:down,ctrl-k:up' \
  --bind 'ctrl-x:execute-silent(cliphist delete <<< {})+reload(cliphist list)')

# `setsid` is load-bearing. wl-copy MUST stay resident — it owns the Wayland
# selection until something replaces it — and while it holds kitty's pty the
# picker window never closes. setsid moves it into its own session so the
# terminal can exit while the clipboard keeps working.
[ -n "$sel" ] && cliphist decode <<< "$sel" | setsid wl-copy >/dev/null 2>&1
