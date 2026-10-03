# Retired: the mode system (2026-09-25 → 2026-10-03)

`mode.sh` switched whole-desk "modes" by RENDERING niri config: `mode.kdl.in` +
`<name>.conf` → `niri/niri/mode.kdl`, validated, then `niri msg action
load-config-file`. It also swapped waybar bars, swaync themes and, at the end,
the Quickshell stack (`BAR=` word).

Retired on purpose: the desk is Quickshell (Signal by default) and **no script
rewrites niri config or keybinds any more**. niri's layout is the hand-kept
`niri/niri/layout.kdl` (Signal's numbers). Style switching is Quickshell-only:
Mod+Shift+T → `scripts/sanctuary/shell.sh set <style>`.

What lives on: the waybar and swaync configs are untouched and are the automatic
fallback (`shell.sh fallback`). These files are kept only as reference — the
mode .conf files record the Default / Zen / Ink numbers if a layout is ever wanted
back by hand.
