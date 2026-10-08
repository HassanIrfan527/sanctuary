# SanctuaryComms — Vencord userplugin

Serves Discord voice state to Quickshell's COMMS card over
`$XDG_RUNTIME_DIR/sanctuary-comms.sock`, and takes `mute` / `deafen` / `leave` back.

- `index.ts` — renderer: reads VoiceStateStore / MediaEngineStore, pushes JSON lines; runs commands
- `native.ts` — main process: the socket server; hands commands to the renderer via a long poll (no code injection)

Edit HERE, then `scripts/sanctuary/vencord.sh build` (copies into
`~/.local/src/Vencord/src/userplugins/`, builds `dist/`). Restart Vesktop.

One-time setup: Vesktop → Settings → Vesktop Settings → **Vencord Location** →
`~/.local/src/Vencord/dist` → restart → Vencord → Plugins → enable **SanctuaryComms**.
Updates: `vencord.sh update` (by hand).
