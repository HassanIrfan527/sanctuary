# Theme backups

Compressed backups of the icon/cursor themes this setup actually uses.
They live in `~/.local/share/icons/` at runtime (a plain dir, not stowed),
so they are archived here for reproducibility.

| Archive | Theme | Notes |
|---|---|---|
| `Cawnonical-Mono-Glyph-Catppuccin-Lavender.tar.gz` | icon theme (active) | **Custom** — White Cawnonical variant recolored to Catppuccin Mocha lavender `#b4befe`. Has no upstream source, so this archive is the only copy. |
| `Drop-Purple.tar.gz` | cursor theme (active) | xcursor, by MOYASH. Source zip also in `~/Downloads/Customization/`. |

## Restore

```bash
for t in ~/.dotfiles/theme-backups/*.tar.gz; do
    tar xzf "$t" -C ~/.local/share/icons/
done
```

Then they're selectable via `gsettings set org.gnome.desktop.interface icon-theme '…'`
/ `cursor-theme '…'`. The active names are wired in `hypr/hypr/autostart.conf`
and `hypr/hypr/env.conf`.

The colorful Cawnonical variants (White/Pink/Cyan/Indigo/Red) and Flatees Outline
were removed to save space; re-fetchable from https://github.com/Celeths/Cawnsole-HTPC
(per-color `.tar.gz` under `packaged/`).
