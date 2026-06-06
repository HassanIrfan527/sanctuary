# Yazi Cheatsheet

Cozy file manager for the Hyprland rice. Theme matches waybar (Catppuccin Mocha).
Open this anytime with `glow ~/.config/yazi/CHEATSHEET.md`, or inside Yazi press **`g ?`**.

## Launching

| Where        | Key / cmd        | What                                        |
|--------------|------------------|---------------------------------------------|
| Hyprland     | `Super + E`      | Yazi in a kitty window                       |
| Hyprland     | `Super + Y`      | Nautilus (the GUI, when you want to *see*)   |
| Shell        | `y`              | Yazi that **cd's your shell** to where you quit |
| Shell        | `yazi`           | plain Yazi (no cd-on-exit)                   |

> `y` is the one to use day-to-day: browse with the keyboard, hit `q`, and your
> terminal is now sitting in that directory. Hit `Q` instead to quit *without* cd-ing.

## Moving around

| Key            | Action                                  |
|----------------|-----------------------------------------|
| `j` / `k`      | down / up                               |
| `h` / `l`      | parent dir / enter dir (or open file)   |
| `gg` / `G`     | top / bottom                            |
| `H` / `L`      | back / forward in history               |
| `z`            | **zoxide** jump to any frecent dir      |
| `Z`            | fzf jump (filename fuzzy find)          |

### Quick jumps (`g` then…)
| Key   | Goes to        |
|-------|----------------|
| `g h` | `~` (home)     |
| `g c` | `~/.config`    |
| `g d` | `~/Downloads`  |
| `g D` | `~/.dotfiles`  *(custom)* |
| `g n` | **reveal current dir in Nautilus** *(custom)* |
| `g ?` | this cheatsheet *(custom)* |

## Selecting

| Key        | Action                                       |
|------------|----------------------------------------------|
| `Space`    | toggle selection, move down                  |
| `v`        | visual select mode (then `j`/`k` to sweep)   |
| `V`        | visual *unselect* mode                       |
| `Ctrl+a`   | select all                                   |
| `Ctrl+r`   | invert selection                             |
| `Esc`      | clear selection                              |

## File operations

| Key        | Action                                       |
|------------|----------------------------------------------|
| `y`        | yank (copy)                                  |
| `x`        | yank (cut)                                   |
| `p`        | paste                                        |
| `P`        | paste **overwriting**                        |
| `d`        | delete → trash                               |
| `D`        | delete **permanently**                       |
| `a`        | create file (end name with `/` for a dir)    |
| `r`        | rename (cursor before extension)             |
| `c c`      | copy full path                               |
| `c d`      | copy dir path                                |
| `c f`      | copy filename                                |

### Bulk rename (the big one)
1. Select files (`Space` / `v`).
2. Press `r`.
3. They open in **nvim** as a plain text list — edit the lines, `:wq`.
4. Yazi applies every rename. Vim motions on filenames = magic.

## Opening

| Key   | Action                                            |
|-------|---------------------------------------------------|
| `Enter` / `l` | open with the default rule                 |
| `o`   | open                                              |
| `O`   | **interactive** open — pick which app             |
| `g n` | reveal the current dir in Nautilus                |
| `!`   | drop into a shell right here *(custom)* — `exit` to return |

### What `O` offers per filetype (first = Enter default)
| File        | Apps in the picker                          |
|-------------|---------------------------------------------|
| video (mkv/mp4/webm/mov/avi…) | **mpv** · VLC · xdg-open · Nautilus |
| audio (mp3/flac/opus…)        | **mpv** · VLC · xdg-open · Nautilus |
| image       | **Loupe** · xdg-open · Brave · Nautilus     |
| svg         | **Loupe** · VS Code · Brave · Nautilus      |
| pdf / epub  | **Okular** · xdg-open · Brave · Nautilus    |
| text/code   | **nvim** · VS Code · xdg-open · Nautilus     |
| html        | **Brave** · VS Code · nvim · Nautilus        |
| anything    | always offers **Reveal in Nautilus**         |

To add another app to the picker, edit `[opener]` + `[open]` in `yazi.toml`.

## Tabs

| Key       | Action                  |
|-----------|-------------------------|
| `t`       | new tab (at cwd)        |
| `1`…`9`   | jump to tab N           |
| `[` / `]` | prev / next tab         |
| `Tab`     | switch tab              |

## Find & filter

| Key   | Action                                        |
|-------|-----------------------------------------------|
| `/`   | find forward (`n`/`N` to cycle)               |
| `?`   | find backward                                 |
| `f`   | filter the listing live                       |
| `s`   | search by filename (fd)                       |
| `S`   | search by content (ripgrep)                   |

## Misc

| Key       | Action                              |
|-----------|-------------------------------------|
| `.`       | toggle hidden files                 |
| `,`       | sort menu                           |
| `Tab`(preview) | spot/preview the hovered file  |
| `w`       | task manager (copy/move progress)   |
| `~` / `F1`| Yazi's built-in keymap help         |
| `q`       | quit (cd's shell if launched via `y`) |
| `Q`       | quit without cd                     |

## Files behind all this
- `~/.config/yazi/yazi.toml`   — behaviour + openers
- `~/.config/yazi/theme.toml`  — colors (mirror of waybar `bottom.css`)
- `~/.config/yazi/keymap.toml` — the custom `g n` / `g D` / `g ?` / `!` binds
- `~/.dotfiles/zsh/utils.zsh`  — the `y` cd-on-exit wrapper
