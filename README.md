# My System config - I'll call it "The Sanctuary"

My system configuration for Fedora —  noctalia shell, vim-first keybinds, and a keyboard-driven workflow.

## FYI

I want a config which feels like home, which feels like a sanctuary, not something I have to do like its a task. This is kinda my hobby now. And you know ricing has no limits or end, where we can say: "Now I have reached my perfect system config, and I don't need anymore tweaks", perfect doesn't exist. So enough yapping, and my main motive is just one line:
"Everything should be controlled by keyboard, and the whole OS is vim" - yeah im obsessed with vim.

So just know that this configuration works for me and it may not work for you.

Fun fact: I did use claude code (vibe-coded), to adjust the hyprland configuration, cause I literally didn't know what to do.

## Core Stack

| Component        | Tool                                                        |
| ---------------- | ----------------------------------------------------------- |
| OS               | Fedora 44                                                   |
| WM               | Niri (Default) + Hyprland                                                    |
| Shell            | Noctalia Shell                                                               |
| Login Manager    | sddm                                                        |
| Terminal         | Kitty (cursor trails, blur, transparency)                   |
| Shell            | Zsh + Starship + zsh-autocomplete + zsh-syntax-highlighting |
| File Manager     | Nautilus (GUI) + Yazi (terminal, vim keybinds)              |
| Editor           | Neovim                                            |
| Browser          | Brave + Zen Browser + Qutebrowser (keyboard-driven)         |
| Fuzzy Finder     | fzf + Television (Rust-based, 30+ channels)                 |

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


### CapsLock = Super

There's no separate vim layer anymore — **hold CapsLock and it _is_ Super**, so every Hyprland keybind above works from the home row (e.g. `CapsLock+h/j/k/l` = move focus, `CapsLock+Shift+h/j/k/l` = move window, `CapsLock+Space` = walker, `CapsLock+n/p` = next/prev workspace). Tap CapsLock for Esc.

