# My System config - I'll call it "The Sanctuary"

My Hyprland desktop configuration for Fedora 43 — dual UI stack with Quickshell (default) and AGS (zen), vim-first keybinds, Material You theming via matugen.

## FYI

I want a config which feels like home, which feels like a sanctuary, not something I have to do like its a task. This is kinda my hobby now. And you know ricing has no limits or end, where we can say: "Now I have reached my perfect system config, and I don't need anymore tweaks", perfect doesn't exist. So enough yapping, and my main motive is just one line:
"Everything should be controlled by keyboard, and the whole OS is vim" - yeah im obsessed with vim.
And you can imagine my obsession with this idea of mine that I'll add a system-wide vim-like navigation structure, where everything would be controlled by vim shortcuts. I thought a lot about it, but it didn't work out in hyprland. But I will find a way.
So you can call me "weird" or a linux nerd. I like these labels btw.

So just know that this configuration works for me and it may not work for you.

## UI Modes

### Default — Quickshell (illogical-impulse)

- Material You colors auto-generated from wallpaper via matugen
- Quickshell bar, dock, sidebars, search, notifications
- Workspace overview, clipboard history, wallpaper selector built-in

## Core Stack

| Component               | Tool                                                        |
| ----------------------- | ----------------------------------------------------------- |
| OS                      | Fedora 43                                                   |
| WM                      | Hyprland                                                    |
| Shell (default)         | Quickshell (illogical-impulse)                              |
| Login Manager           | sddm                                                        |
| Terminal                | Kitty (cursor trails, blur, transparency)                   |
| Shell                   | Zsh + Starship + zsh-autocomplete + zsh-syntax-highlighting |
| File Manager            | Nautilus (GUI) + Yazi (terminal, vim keybinds)              |
| Editor                  | VS Code + Neovim                                            |
| Browser                 | Google Chrome + Zen Browser + Qutebrowser (keyboard-driven) |
| Launcher (default)      | Quickshell search / Fuzzel fallback                         |
| Notifications (default) | Quickshell built-in                                         |
| Lock Screen             | Hyprlock                                                    |
| Idle Daemon             | Hypridle                                                    |
| Logout Menu             | Wlogout                                                     |
| Wallpaper               | swww (animated support)                                     |
| Night Light             | Gammastep (3800K always-on)                                 |
| Color Generation        | Matugen (Material You from wallpaper)                       |
| Clipboard               | Cliphist                                                    |
| Screenshots             | Grimblast + Hyprshot                                        |
| Fetch                   | Fastfetch + Kotofetch                                       |
| Fuzzy Finder            | fzf + Television (Rust-based, 30+ channels)                 |
| Multiplexer             | Tmux (Alt+a prefix, Catppuccin theme)                       |
| Recording               | Asciinema (terminal) + wf-recorder (screen)                 |
| Cat Replacement         | Bat (syntax highlighted cat)                                |
| Smart cd                | Zoxide (frecency-based directory jumping)                   |

## CLI & TUI Tools

| Package    | What it does                                                                                                |
| ---------- | ----------------------------------------------------------------------------------------------------------- |
| television | Rust-based fuzzy finder with 30+ channels (files, text, git, docker, env)                                   |
| fzf        | Classic fuzzy finder — Ctrl+R history, Ctrl+T files, Alt+C cd (via `/usr/share/fzf/shell/key-bindings.zsh`) |
| asciinema  | Record terminal sessions                                                                                    |
| bat        | Syntax-highlighted cat replacement                                                                          |
| glow       | Terminal markdown renderer (pretty-prints README/docs)                                                      |
| sheets     | Terminal spreadsheet (CSV viewer/editor)                                                                    |
| tldr       | Simplified man pages with examples                                                                          |
| thefuck    | Corrects the previous shell command — type `fuck` to fix typos                                              |
| weathr     | ASCII terminal weather app (animated conditions, auto-location)                                             |
| zoxide     | Smart cd that learns your frequent directories                                                              |
| podman-tui | TUI for managing Podman containers, images, volumes                                                         |
| direnv     | Auto-loads .envrc per directory (venv activation, env vars)                                                 |

## Additional Desktop Apps

| App                    | Purpose                      |
| ---------------------- | ---------------------------- |
| Blender                | For 2d/3d animation creation |
| Libresprite / Asperite | For pixel art generation     |
| Ente Auth              | For 2FA authentication       |

## Keyboard Setup

### Keyd (system-level)

CapsLock is remapped via keyd (`/etc/keyd/default.conf`):

- **CapsLock hold** — vim layer (hjkl = arrows, w/b = word nav, y/p = copy/paste, u = undo)
- **CapsLock tap** — Super key
- **CapsLock hold + Space** — one-shot numpad layer (uio=789, jkl=456, m,.=123)

### Hyprland Keybinds

#### Apps

| Key           | Action         |
| ------------- | -------------- |
| `Super+Enter` | Kitty terminal |
| `Super+E`     | Nautilus       |
| `Super+Y`     | Yazi           |
| `Super+B`     | Chrome         |
| `Super+C`     | VS Code        |

#### Quickshell Panels (default mode)

| Key             | Action                        |
| --------------- | ----------------------------- |
| `Super+Space`   | Search / app launcher         |
| `Super+Tab`     | Workspace overview            |
| `Super+A`       | Left sidebar (AI chat)        |
| `Super+.`       | Right sidebar (notifications) |
| `Super+/`       | Keybind cheatsheet            |
| `Super+Shift+V` | Clipboard history             |
| `Super+Shift+W` | Wallpaper selector            |
| `Super+Ctrl+M`  | Media controls                |
| `Ctrl+Alt+Del`  | Session menu                  |
| `Ctrl+Super+R`  | Restart Quickshell            |

#### Windows (vim-style)

| Key                  | Action                   |
| -------------------- | ------------------------ |
| `Super+HJKL`         | Focus left/down/up/right |
| `Super+Arrows`       | Focus left/down/up/right |
| `Super+Shift+HJKL`   | Move window              |
| `Super+Shift+Arrows` | Move window              |
| `Super+Alt+HJKL`     | Resize window            |
| `Super+W`            | Close window             |
| `Super+F`            | Maximize                 |
| `Super+Shift+F`      | Fullscreen               |
| `Super+V`            | Toggle floating          |
| `Super+S`            | Toggle split direction   |

#### Workspaces

| Key                      | Action                        |
| ------------------------ | ----------------------------- |
| `Super+Numpad 1-9`       | Switch workspace              |
| `Super+1-9`              | Switch workspace (number row) |
| `Super+Shift+Numpad 1-9` | Move window to workspace      |
| `CapsLock+N`             | Previous workspace            |
| `CapsLock+M`             | Next workspace                |

#### System

| Key             | Action                                       |
| --------------- | -------------------------------------------- |
| `Super+Escape`  | Lock screen                                  |
| `Super+Delete`  | Logout menu                                  |
| `Super+Shift+T` | Theme switcher (default/cozy-night/cozy-day) |
| `Super+Shift+P` | Play/Pause                                   |
| `Super+Shift+]` | Next track                                   |
| `Super+Shift+[` | Previous track                               |
| `Print`         | Screenshot area to clipboard                 |
| `Shift+Print`   | Screenshot full screen                       |
| `Super+Shift+=` | Night light warmer                           |
| `Super+Shift+-` | Night light cooler                           |
| `Super+Shift+B` | Toggle key sounds on/off                     |
| `Super+Alt+B`   | Switch key sound theme                       |

### Tmux (Prefix: Ctrl+A)

| Key            | Action            |
| -------------- | ----------------- |
| `Ctrl+A, c`    | New tab           |
| `Ctrl+A, n/p`  | Next/previous tab |
| `Ctrl+A, v`    | Split vertical    |
| `Ctrl+A, s`    | Split horizontal  |
| `Ctrl+A, hjkl` | Navigate panes    |
| `Ctrl+A, HJKL` | Resize panes      |
| `Ctrl+A, z`    | Zoom pane         |
| `Ctrl+A, x`    | Kill pane         |
| `Ctrl+A, w`    | Kill tab          |

### Vim Layer (CapsLock hold)

| Key     | Action                |
| ------- | --------------------- |
| `hjkl`  | Arrow keys            |
| `w/b`   | Word forward/backward |
| `0/4`   | Home/End              |
| `y/p`   | Copy/Paste            |
| `u`     | Undo                  |
| `x`     | Delete                |
| `v`     | Select all            |
| `Space` | One-shot numpad mode  |

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
  nwg-dock-hyprland nwg-look wlogout cliphist walker

# Terminal and tools
sudo dnf install -y kitty zsh zsh-syntax-highlighting tmux bat zoxide \
  starship fastfetch asciinema fzf tldr thefuck qutebrowser

# Markdown/spreadsheet TUIs (Go-based — installed via `go install`)
go install github.com/charmbracelet/glow@latest
go install github.com/maaslalani/sheets@latest

# Rust-based CLI tools
cargo install television weathr

# Utils
sudo dnf install -y brightnessctl playerctl pamixer gammastep \
  wl-clipboard grim slurp polkit-gnome keyd jq socat bc stow

# Fonts
sudo dnf install -y jetbrains-mono-nerd-fonts google-rubik-vf-fonts \
  readex-pro-fonts-all google-material-symbols-vf-rounded-fonts \
  twitter-twemoji-fonts adw-gtk3-theme

# Cargo
cargo install matugen

# Key sounds (bucklespring with libinput+mouse/scroll patch)
# See keysounds/README.md for build instructions
sudo dnf install -y openal-soft-devel alure-devel libinput-devel systemd-devel
cd /tmp && git clone https://github.com/zevv/bucklespring.git
# Apply the libinput mouse/scroll patch from keysounds/scan-libinput.c
cp ~/.dotfiles/keysounds/scan-libinput.c /tmp/bucklespring/
cd /tmp/bucklespring && make clean && make libinput=1
cp buckle ~/.local/bin/buckle
sudo usermod -aG input $USER  # required for key event access

# Flatpak
flatpak install flathub io.github.sxyazi.yazi
```

### 2. Clone and stow

```bash
git clone https://github.com/HassanIrfan527/triland ~/.dotfiles
cd ~/.dotfiles

# Stow configs into ~/.config/
stow hypr hypridle hyprlock kitty quickshell matugen fuzzel rofi swaync waybar walker wlogout yazi themes fastfetch kotofetch illogical-impulse starship nvim vscode qutebrowser television glow ags

# Stow zsh configs into ~/ (zshrc and p10k live in home dir)
stow -t ~ zsh

# Stow git config into ~/
stow -t ~ git
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
├── hypridle/                  # Idle daemon config
├── hyprlock/                  # Lock screen config
├── kitty/kitty/               # Kitty terminal
├── quickshell/quickshell/ii/  # Quickshell shell
├── matugen/matugen/           # Color generation templates
├── fuzzel/fuzzel/             # Fuzzel launcher
├── rofi/                      # Rofi launcher
├── swaync/                    # SwayNotificationCenter
├── waybar/                    # Waybar (cozy mode)
├── walker/                    # Walker launcher
├── wlogout/wlogout/           # Logout menu
├── yazi/yazi/                 # Terminal file manager
├── qutebrowser/qutebrowser/   # Qutebrowser (keyboard-driven browser)
├── nvim/                      # Neovim config
├── vscode/                    # VS Code settings
├── fastfetch/fastfetch/       # System fetch
├── kotofetch/kotofetch/       # Quote fetch
├── starship/                  # Prompt theme
├── zsh/                       # Zsh + Powerlevel10k config
├── git/                       # Gitconfig + work profile + hooks
├── illogical-impulse/         # Quickshell user config
├── ags/ags/                   # AGS/Astal shell (WIP replacement for Quickshell)
├── television/television/     # Television fuzzy finder config + cable channels
├── glow/glow/                 # Glow markdown renderer config
├── keyd/                      # Keyd config (backup)
├── keysounds/                 # Bucklespring + MechSim keysound configs
├── scripts/                   # Helper scripts (ags-run, ags-reload, etc.)
├── tmux.conf                  # Tmux config (backup)
├── themes/themes/             # Theme/UI stack switcher
├── qylock/                    # Qylock lock screen
└── plymouth/thunder-hud/      # Boot animation
```

## GNOME Coexistence

Runs alongside GNOME 49 — select either at GDM login. XDG portal isolation, GTK theming via gsettings, env vars isolated in `env.conf`.

## Credits

- [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) — Quickshell illogical-impulse
- [Darkkal44/qylock](https://github.com/Darkkal44/qylock?tab=readme-ov-file#gallery) - sddm themes
