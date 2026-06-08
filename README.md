# My System config - I'll call it "The Sanctuary"

My Hyprland desktop configuration for Fedora 43 — a cozy, minimal Waybar setup with a desk-pet, vim-first keybinds, and a keyboard-driven workflow.

## FYI

I want a config which feels like home, which feels like a sanctuary, not something I have to do like its a task. This is kinda my hobby now. And you know ricing has no limits or end, where we can say: "Now I have reached my perfect system config, and I don't need anymore tweaks", perfect doesn't exist. So enough yapping, and my main motive is just one line:
"Everything should be controlled by keyboard, and the whole OS is vim" - yeah im obsessed with vim.
And you can imagine my obsession with this idea of mine that I'll add a system-wide vim-like navigation structure, where everything would be controlled by vim shortcuts. I thought a lot about it, but it didn't work out in hyprland. But I will find a way.
So you can call me "weird" or a linux nerd. I like these labels btw.

So just know that this configuration works for me and it may not work for you.

Fun fact: I did use claude code (vibe-coded), to adjust the hyprland configuration, cause I literally didn't know what to do.

## The Bar — Cozy Waybar

The whole desktop shell is just a single, deliberately minimal **Waybar** — no Quickshell, no AGS, no big widget framework. It's a frosted bar with soft accent pills tuned for legibility (layer blur, not matugen), restarted clean rather than via SIGUSR2.

Layout:

- **Left** — Hyprland workspaces + `mpris` now-playing
- **Center** — clock
- **Right** — system tray

Notifications are handled by **swaync**.

## Core Stack

| Component        | Tool                                                        |
| ---------------- | ----------------------------------------------------------- |
| OS               | Fedora 43                                                   |
| WM               | Hyprland                                                    |
| Bar / Shell      | Waybar (cozy frosted bar)                                   |
| Login Manager    | sddm                                                        |
| Terminal         | Kitty (cursor trails, blur, transparency)                   |
| Shell            | Zsh + Starship + zsh-autocomplete + zsh-syntax-highlighting |
| File Manager     | Nautilus (GUI) + Yazi (terminal, vim keybinds)              |
| Editor           | VS Code + Neovim                                            |
| Browser          | Brave + Zen Browser + Qutebrowser (keyboard-driven)         |
| Launcher         | Walker (elephant backend) + Fuzzel for `--dmenu` pickers    |
| Notifications    | swaync                                                      |
| OSD              | swayosd (volume/brightness)                                 |
| Lock Screen      | Hyprlock                                                    |
| Idle Daemon      | Hypridle                                                    |
| Wallpaper        | swww (animated support)                                     |
| Night Light      | hyprsunset (3800K always-on, CTM protocol)                  |
| Clipboard        | Cliphist (via Walker)                                       |
| Screenshots      | Grim + Slurp → clipboard, Satty for editing                 |
| Fetch            | Fastfetch + Kotofetch                                       |
| Fuzzy Finder     | fzf + Television (Rust-based, 30+ channels)                 |
| Multiplexer      | Tmux (Ctrl+A prefix, Catppuccin theme)                      |
| Recording        | Asciinema (terminal) + wf-recorder (screen)                 |
| Cat Replacement  | Bat (syntax highlighted cat)                                |
| Smart cd         | Zoxide (frecency-based directory jumping)                   |

## CLI & TUI Tools

| Package     | What it does                                                                                                |
| ----------- | ----------------------------------------------------------------------------------------------------------- |
| television  | Rust-based fuzzy finder with 30+ channels (files, text, git, docker, env)                                   |
| fzf         | Classic fuzzy finder — Ctrl+R history, Ctrl+T files, Alt+C cd (via `/usr/share/fzf/shell/key-bindings.zsh`) |
| asciinema   | Record terminal sessions                                                                                    |
| bat         | Syntax-highlighted cat replacement                                                                          |
| glow        | Terminal markdown renderer (pretty-prints README/docs)                                                      |
| sheets      | Terminal spreadsheet (CSV viewer/editor)                                                                    |
| tldr        | Simplified man pages with examples                                                                          |
| thefuck     | Corrects the previous shell command — type `fuck` to fix typos                                              |
| weathr      | ASCII terminal weather app (animated conditions, auto-location)                                             |
| zoxide      | Smart cd that learns your frequent directories                                                              |
| podman-tui  | TUI for managing Podman containers, images, volumes                                                         |
| harlequin   | SQL IDE TUI — Postgres/MySQL/SQLite/DuckDB with autocomplete, query history, result grid                    |
| direnv      | Auto-loads .envrc per directory (venv activation, env vars)                                                 |
| dozzle      | An amazing logger for podman containers                                                                     |
| lnav        | A TUI package for viewing logs better. its amazing                                                          |
| clickup-cli | A CLI package for clickup. Its great since clickup is slow on the browser and in the app too.               |
| pi          | Alternative to claude code. Simple, extensible and amazing. Check it out at [pi.dev](https://pi.dev)        |
| opencode    | Currently testing it, if it can be a replacement to claude code.                                            |
| patent      | A rust TUI tool which researches and tells you if your dev-tool idea already exists or not.                 |

## Additional Desktop Apps

| App                    | Purpose                      |
| ---------------------- | ---------------------------- |
| Blender                | For 2d/3d animation creation |
| Libresprite / Asperite | For pixel art generation     |
| Ente Auth              | For 2FA authentication       |

## Keyboard Setup

### Keyd (system-level)

CapsLock is remapped via keyd (`/etc/keyd/default.conf`) with one line — `capslock = overload(meta, esc)`:

- **CapsLock hold** — acts as the Super (Meta) modifier, so `CapsLock+<key>` == `Super+<key>`
- **CapsLock tap** — Esc

That's the whole keyd config. All shortcuts live in `keybinds.conf` (single source of truth) — every `Super+…` bind below is reachable from the home row via CapsLock. The OS-wide vim editing layer was dropped on purpose: every surface is already vim (Neovim, tmux, vimium, TUIs), so it was redundant.

### Hyprland Keybinds

#### Apps

| Key           | Action                  |
| ------------- | ----------------------- |
| `Super+Enter` | Kitty terminal          |
| `Super+E`     | Nautilus                |
| `Super+Y`     | Yazi                    |
| `Super+B`     | Brave                   |
| `Super+Z`     | Zen browser             |
| `Super+O`     | Toggle bottom bar       |

#### Launcher & Drawers

| Key             | Action                          |
| --------------- | ------------------------------- |
| `Super+Space`   | Walker app launcher             |
| `Super+Delete`  | Walker command palette          |
| `Super+V`       | Walker clipboard history        |
| `Super+/`       | Keybind cheatsheet              |
| `Super+Shift+W` | Wallpaper picker                |
| `Super+.`       | Japanese recall drawer          |
| `Super+A`       | Affirmation drawer              |
| `Super+Alt+A`   | Ambient soundscapes             |
| `Super+Shift+C` | Color picker (hex to clipboard) |
| `Super+Semicolon` | Window jump                   |

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
| `Super+N` / `CapsLock+n` | Next workspace                |
| `Super+P` / `CapsLock+p` | Previous workspace            |
| `Super+C` / `CapsLock+c` | New empty workspace           |
| `Super+'` / `CapsLock+'`  | Last workspace (back-and-forth) |

#### System

| Key             | Action                            |
| --------------- | --------------------------------- |
| `Super+Escape`  | Lock screen                       |
| `Super+M`       | Caffeine (keep screen awake)      |
| `Super+Shift+M` | Play/Pause                        |
| `Super+Shift+]` | Next track                        |
| `Super+Shift+[` | Previous track                    |
| `Print`         | Screenshot area to clipboard      |
| `Shift+Print`   | Screenshot area, edit in Satty    |
| `Super+Print`   | Screenshot full screen            |
| `Super+Shift+=` | Night light warmer                |
| `Super+Shift+-` | Night light cooler                |
| `Super+Shift+0` | Night light reset (3800K)         |
| `Super+Shift+B` | Toggle key sounds on/off          |
| `Super+Alt+B`   | Switch key sound theme            |
| `Super+I`       | Bug capture                       |

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

### CapsLock = Super

There's no separate vim layer anymore — **hold CapsLock and it _is_ Super**, so every Hyprland keybind above works from the home row (e.g. `CapsLock+h/j/k/l` = move focus, `CapsLock+Shift+h/j/k/l` = move window, `CapsLock+Space` = walker, `CapsLock+n/p` = next/prev workspace). Tap CapsLock for Esc.

## Installation

### 1. Install packages

```bash
# COPR repos
sudo dnf copr enable sdegler/hyprland -y

# Core
sudo dnf install -y hyprland xdg-desktop-portal-hyprland hyprlock hypridle \
  hyprpicker hyprsunset swww hyprpolkitagent hyprland-qtutils

# Bar, launcher & notifications
sudo dnf install -y waybar fuzzel SwayNotificationCenter swayosd \
  cliphist walker satty wiremix

# Terminal and tools
sudo dnf install -y kitty zsh zsh-syntax-highlighting tmux bat zoxide \
  starship fastfetch asciinema fzf tldr thefuck qutebrowser

# Markdown/spreadsheet TUIs (Go-based — installed via `go install`)
go install github.com/charmbracelet/glow@latest
go install github.com/maaslalani/sheets@latest

# Rust-based CLI tools
cargo install television weathr

# Utils
sudo dnf install -y brightnessctl playerctl pamixer \
  wl-clipboard grim slurp keyd jq socat bc stow

# Fonts
sudo dnf install -y jetbrains-mono-nerd-fonts google-rubik-vf-fonts \
  readex-pro-fonts-all google-material-symbols-vf-rounded-fonts \
  twitter-twemoji-fonts adw-gtk3-theme

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
stow hypr hypridle hyprlock kitty fuzzel swaync waybar walker elephant yazi themes fastfetch kotofetch starship nvim vscode qutebrowser television glow

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

### 4. XDG portal (GNOME coexistence)

```bash
sudo tee /usr/share/xdg-desktop-portal/hyprland-portals.conf << 'EOF'
[preferred]
default=hyprland;gtk
org.freedesktop.impl.portal.Secret=gnome-keyring
org.freedesktop.impl.portal.FileChooser=gtk
EOF
```

### 5. Select Hyprland at GDM login screen

## Dotfiles Structure

```
~/.dotfiles/
├── hypr/hypr/                 # Hyprland configs + scripts
├── hypridle/                  # Idle daemon config
├── hyprlock/                  # Lock screen config
├── kitty/kitty/               # Kitty terminal
├── fuzzel/fuzzel/             # Fuzzel (--dmenu pickers)
├── swaync/                    # SwayNotificationCenter
├── waybar/                    # Waybar (cozy frosted bar)
├── walker/                    # Walker launcher
├── elephant/                  # Walker (elephant) backend menus
├── yazi/yazi/                 # Terminal file manager
├── qutebrowser/qutebrowser/   # Qutebrowser (keyboard-driven browser)
├── nvim/                      # Neovim config
├── vscode/                    # VS Code settings
├── fastfetch/fastfetch/       # System fetch
├── kotofetch/kotofetch/       # Quote fetch
├── starship/                  # Prompt theme
├── zsh/                       # Zsh + Powerlevel10k config
├── git/                       # Gitconfig + work profile + hooks
├── television/television/     # Television fuzzy finder config + cable channels
├── glow/glow/                 # Glow markdown renderer config
├── keyd/                      # Keyd config (backup)
├── keysounds/                 # Bucklespring + MechSim keysound configs
├── scripts/                   # Helper scripts
├── tmux.conf                  # Tmux config (backup)
├── themes/themes/             # Theme switcher
├── qylock/                    # Qylock lock screen
└── plymouth/thunder-hud/      # Boot animation
```

## GNOME Coexistence

Runs alongside GNOME 49 — select either at GDM login. XDG portal isolation, GTK theming via gsettings, env vars isolated in `env.conf`.

## Credits

- [Darkkal44/qylock](https://github.com/Darkkal44/qylock?tab=readme-ov-file#gallery) - sddm themes
