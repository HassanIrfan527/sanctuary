# Key Sounds

Mechanical keyboard sound effects on every keypress, mouse click, and scroll. Uses a patched version of [bucklespring](https://github.com/zevv/bucklespring) with libinput support for Wayland + mouse/scroll events.

## What's patched

The upstream bucklespring only supports keyboard sounds on the libinput backend. This patch adds:
- **Mouse click sounds** (left/right/middle) — scancode `0xff`
- **Scroll wheel sounds** — scancode `0xfe`

The patched file is `scan-libinput.c` in this directory.

## Sound Themes

### ibm-model-m
The default bucklespring sounds. IBM Model M buckling spring keyboard — loud, clicky, satisfying. Each key has a unique press and release sound.

### maligna-kodera
Softer, game-inspired sounds from [maligna kodera](https://github.com/Krzyhau/maligna-kodera-classic) (CC0 licensed, sourced from freesound.org). 8 key variations distributed across the keyboard, with distinct enter and backspace sounds.

## Build & Install

### Dependencies (Fedora)
```bash
sudo dnf install -y openal-soft-devel alure-devel libinput-devel systemd-devel
```

### Build
```bash
git clone https://github.com/zevv/bucklespring.git /tmp/bucklespring
cp ~/.dotfiles/keysounds/scan-libinput.c /tmp/bucklespring/
cd /tmp/bucklespring
make clean && make libinput=1
cp buckle ~/.local/bin/buckle
```

### Input group access
```bash
sudo usermod -aG input $USER
# Log out and back in
```

## Setup Sound Themes

```bash
# Copy themes to the sounds directory
cp -r ~/.dotfiles/keysounds/themes/* ~/.local/share/bucklespring-sounds/

# Set the active theme
mkdir -p ~/.config/bucklespring
echo "ibm-model-m" > ~/.config/bucklespring/theme
```

## Usage

### Keybinds
| Key | Action |
|-----|--------|
| `Super+Shift+B` | Toggle key sounds on/off |
| `Super+Alt+B` | Switch sound theme (fuzzel picker) |

### Manual
```bash
# Run with a specific theme
buckle -f -p ~/.local/share/bucklespring-sounds/ibm-model-m

# Disable mouse click sounds
buckle -f -c -p ~/.local/share/bucklespring-sounds/ibm-model-m

# Adjust volume (0-100)
buckle -f -g 50 -p ~/.local/share/bucklespring-sounds/ibm-model-m
```

## Adding New Themes

1. Create a directory in `~/.local/share/bucklespring-sounds/your-theme/`
2. Add wav files named by scancode: `{hex}-0.wav` (press) and `{hex}-1.wav` (release)
3. Common scancodes: `1c` = Enter, `0e` = Backspace, `39` = Space, `ff` = Mouse click, `fe` = Scroll
4. Use `-f` flag so missing keys fall back to a default sound
5. The theme appears automatically in the `Super+Alt+B` picker
