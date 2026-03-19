# triland

My Hyprland desktop configuration for Fedora 43 — dual UI stack with Quickshell (default) and Waybar (cozy), vim-first keybinds, Material You theming via matugen.

## UI Modes

### Default — Quickshell (illogical-impulse)
- Material You colors auto-generated from wallpaper via matugen
- Quickshell bar, dock, sidebars, search, notifications
- Workspace overview, clipboard history, wallpaper selector built-in

### Cozy — Waybar + Wofi + Swaync
- Everforest color scheme (dark + light variants)
- Illustrated summer wallpapers
- Rounded waybar with 3D border effect
- Switch with `Super+Shift+T`

## Core Stack

| Component | Tool |
|-----------|------|
| OS | Fedora 43 |
| WM | Hyprland |
| Shell (default) | Quickshell (illogical-impulse) |
| Shell (cozy) | Waybar + Wofi + Swaync |
| Terminal | Kitty (cursor trails, blur, transparency) |
| Shell | Zsh + Starship + zsh-autocomplete + zsh-syntax-highlighting |
| File Manager | Nautilus (GUI) + Yazi (terminal, vim keybinds) |
| Editor | VS Code + Neovim |
| Browser | Google Chrome + Zen Browser |
| Launcher (default) | Quickshell search / Fuzzel fallback |
| Launcher (cozy) | Wofi |
| Notifications (default) | Quickshell built-in |
| Notifications (cozy) | SwayNotificationCenter |
| Lock Screen | Hyprlock |
| Idle Daemon | Hypridle |
| Logout Menu | Wlogout |
| Wallpaper | swww (animated support) |
| Night Light | Gammastep (3800K always-on) |
| Color Generation | Matugen (Material You from wallpaper) |
| Clipboard | Cliphist |
| Screenshots | Grimblast + Hyprshot |
| Fetch | Fastfetch + Kotofetch |
| Multiplexer | Tmux (Ctrl+A prefix, Catppuccin theme) |
| Recording | Asciinema (terminal) + wf-recorder (screen) |
| Cat Replacement | Bat (syntax highlighted cat) |
| Smart cd | Zoxide (frecency-based directory jumping) |

## Keyboard Setup

### Keyd (system-level)
CapsLock is remapped via keyd (`/etc/keyd/default.conf`):
- **CapsLock hold** — vim layer (hjkl = arrows, w/b = word nav, y/p = copy/paste, u = undo)
- **CapsLock tap** — Super key
- **CapsLock hold + Space** — one-shot numpad layer (uio=789, jkl=456, m,.=123)

### Hyprland Keybinds

#### Apps
| Key | Action |
|-----|--------|
| `Super+Enter` | Kitty terminal |
| `Super+E` | Nautilus |
| `Super+Y` | Yazi |
| `Super+B` | Chrome |
| `Super+C` | VS Code |

#### Quickshell Panels (default mode)
| Key | Action |
|-----|--------|
| `Super+Space` | Search / app launcher |
| `Super+Tab` | Workspace overview |
| `Super+A` | Left sidebar (AI chat) |
| `Super+.` | Right sidebar (notifications) |
| `Super+/` | Keybind cheatsheet |
| `Super+Shift+V` | Clipboard history |
| `Super+Shift+W` | Wallpaper selector |
| `Super+Ctrl+M` | Media controls |
| `Ctrl+Alt+Del` | Session menu |
| `Ctrl+Super+R` | Restart Quickshell |

#### Windows (vim-style)
| Key | Action |
|-----|--------|
| `Super+HJKL` | Focus left/down/up/right |
| `Super+Arrows` | Focus left/down/up/right |
| `Super+Shift+HJKL` | Move window |
| `Super+Shift+Arrows` | Move window |
| `Super+Alt+HJKL` | Resize window |
| `Super+W` | Close window |
| `Super+F` | Maximize |
| `Super+Shift+F` | Fullscreen |
| `Super+V` | Toggle floating |
| `Super+S` | Toggle split direction |

#### Workspaces
| Key | Action |
|-----|--------|
| `Super+Numpad 1-9` | Switch workspace |
| `Super+1-9` | Switch workspace (number row) |
| `Super+Shift+Numpad 1-9` | Move window to workspace |
| `CapsLock+N` | Previous workspace |
| `CapsLock+M` | Next workspace |

#### System
| Key | Action |
|-----|--------|
| `Super+Escape` | Lock screen |
| `Super+Delete` | Logout menu |
| `Super+Shift+T` | Theme switcher (default/cozy-night/cozy-day) |
| `Super+Shift+P` | Play/Pause |
| `Super+Shift+]` | Next track |
| `Super+Shift+[` | Previous track |
| `Print` | Screenshot area to clipboard |
| `Shift+Print` | Screenshot full screen |
| `Super+Shift+=` | Night light warmer |
| `Super+Shift+-` | Night light cooler |

### Tmux (Prefix: Ctrl+A)
| Key | Action |
|-----|--------|
| `Ctrl+A, c` | New tab |
| `Ctrl+A, n/p` | Next/previous tab |
| `Ctrl+A, v` | Split vertical |
| `Ctrl+A, s` | Split horizontal |
| `Ctrl+A, hjkl` | Navigate panes |
| `Ctrl+A, HJKL` | Resize panes |
| `Ctrl+A, z` | Zoom pane |
| `Ctrl+A, x` | Kill pane |
| `Ctrl+A, w` | Kill tab |

### Vim Layer (CapsLock hold)
| Key | Action |
|-----|--------|
| `hjkl` | Arrow keys |
| `w/b` | Word forward/backward |
| `0/4` | Home/End |
| `y/p` | Copy/Paste |
| `u` | Undo |
| `x` | Delete |
| `v` | Select all |
| `Space` | One-shot numpad mode |

## Installation

### 1. Install packages
```bash
# COPR repos
sudo dnf copr enable ririko66z/dots-hyprland -y
sudo dnf copr enable sdegler/hyprland -y

# Core
sudo dnf install -y hyprland xdg-desktop-portal-hyprland hyprlock hypridle \
  hyprpicker hyprsunset hyprshot swww grimblast quickshell-git

# UI
sudo dnf install -y waybar wofi rofi fuzzel SwayNotificationCenter \
  nwg-dock-hyprland nwg-look wlogout cliphist

# Terminal and tools
sudo dnf install -y kitty zsh zsh-syntax-highlighting tmux bat zoxide \
  starship fastfetch asciinema

# Utils
sudo dnf install -y brightnessctl playerctl pamixer gammastep \
  wl-clipboard grim slurp polkit-gnome keyd jq socat bc stow

# Fonts
sudo dnf install -y jetbrains-mono-nerd-fonts google-rubik-vf-fonts \
  readex-pro-fonts-all google-material-symbols-vf-rounded-fonts \
  twitter-twemoji-fonts adw-gtk3-theme

# Cargo
cargo install matugen

# Flatpak
flatpak install flathub io.github.sxyazi.yazi
```

### 2. Clone and stow
```bash
git clone https://github.com/HassanIrfan527/triland ~/.dotfiles
cd ~/.dotfiles
stow hypr kitty quickshell matugen fuzzel wlogout yazi themes fastfetch kotofetch illogical-impulse starship
```

### 3. Keyd setup
```bash
sudo cp keyd/default.conf /etc/keyd/default.conf
sudo systemctl enable keyd --now
sudo keyd reload
```

### 4. Quickshell Python venv
```bash
uv venv --prompt .venv ~/.local/state/quickshell/.venv -p 3.12
source ~/.local/state/quickshell/.venv/bin/activate
uv pip install pillow pywayland psutil materialyoucolor libsass numpy opencv-contrib-python
deactivate
```

### 5. XDG portal (GNOME coexistence)
```bash
sudo tee /usr/share/xdg-desktop-portal/hyprland-portals.conf << 'EOF'
[preferred]
default=hyprland;gtk
org.freedesktop.impl.portal.Secret=gnome-keyring
org.freedesktop.impl.portal.FileChooser=gtk
EOF
```

### 6. Select Hyprland at GDM login screen

## Dotfiles Structure

```
~/.dotfiles/
├── hypr/hypr/                 # Hyprland configs
├── kitty/kitty/               # Kitty terminal
├── quickshell/quickshell/ii/  # Quickshell shell
├── matugen/matugen/           # Color generation templates
├── fuzzel/fuzzel/             # Fuzzel launcher
├── wlogout/wlogout/           # Logout menu
├── yazi/yazi/                 # Terminal file manager
├── fastfetch/fastfetch/       # System fetch
├── kotofetch/kotofetch/       # Quote fetch
├── starship/                  # Prompt theme
├── illogical-impulse/         # Quickshell user config
├── keyd/                      # Keyd config (backup)
├── tmux.conf                  # Tmux config (backup)
├── themes/themes/             # Theme/UI stack switcher
├── cozy/                      # Cozy theme (Everforest)
└── plymouth/thunder-hud/      # Boot animation
```

## GNOME Coexistence

Runs alongside GNOME 49 — select either at GDM login. XDG portal isolation, GTK theming via gsettings, env vars isolated in `env.conf`.

## Credits

- [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) — Quickshell illogical-impulse
- Summer Day and Night — Cozy Everforest waybar theme
