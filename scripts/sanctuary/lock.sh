#!/usr/bin/env bash
# The locker, in the island language: square, monospace, Mocha, one field.
# Reached via `loginctl lock-session`, which swayidle's `lock` handler runs —
# that is the correct chain, so screen-lock also fires on suspend and on idle
# without a second code path.
exec swaylock \
  --daemonize \
  --ignore-empty-password \
  --show-failed-attempts \
  --indicator-radius 52 \
  --indicator-thickness 2 \
  --ring-color 45475a \
  --ring-ver-color b4befe \
  --ring-wrong-color f38ba8 \
  --ring-clear-color fab387 \
  --inside-color 11111b \
  --inside-ver-color 11111b \
  --inside-wrong-color 11111b \
  --inside-clear-color 11111b \
  --key-hl-color cba6f7 \
  --bs-hl-color f38ba8 \
  --separator-color 00000000 \
  --text-color cdd6f4 \
  --text-ver-color b4befe \
  --text-wrong-color f38ba8 \
  --text-clear-color fab387 \
  --line-color 00000000 \
  --line-ver-color 00000000 \
  --line-wrong-color 00000000 \
  --line-clear-color 00000000 \
  --font "JetBrainsMono Nerd Font" \
  --font-size 12 \
  --screenshots \
  --effect-blur 7x3 \
  --effect-vignette 0.4:0.4 \
  --fade-in 0.16
