#!/usr/bin/env bash
#
# install.sh — a tiny, explicit replacement for GNU Stow.
#
# SAFETY:
#   - If a link is already correct, it's left alone (idempotent).
#   - If something REAL is in the way, it's moved to a timestamped backup
#     dir, never deleted.
#   - Real config DIRECTORIES that aren't managed here are skipped with a
#     warning, never overwritten.
#   - nvim is intentionally NOT listed — it lives in its own repo now.
#
# USAGE:
#   ./install.sh            apply the links
#   ./install.sh --dry-run  show what would happen, change nothing
#
set -euo pipefail

# The repo root = wherever this script lives (resolves through symlinks).
DOTFILES="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

DRY_RUN=0
[[ "${1:-}" == "--dry-run" || "${1:-}" == "-n" ]] && DRY_RUN=1

# ── The manifest ─────────────────────────────────────────────────────
# Format: "SOURCE_IN_REPO : DESTINATION_ON_DISK"
# SOURCE is relative to this repo. DESTINATION may use ~ for $HOME.
# Destinations mostly land in ~/.config, but a few go straight to $HOME.
LINKS=(
  # ── whole-directory links into ~/.config ──
  "elephant/elephant     : ~/.config/elephant"
  "fuzzel/fuzzel         : ~/.config/fuzzel"
  "glow/glow             : ~/.config/glow"
  "hypr/hypr             : ~/.config/hypr"
  "hyprlock/hyprlock     : ~/.config/hyprlock"
  "mako/mako             : ~/.config/mako"
  "qylock/qylock         : ~/.config/qylock"
  "swaync/swaync         : ~/.config/swaync"
  "swayosd/swayosd       : ~/.config/swayosd"
  "television/television : ~/.config/television"
  "themes/themes         : ~/.config/themes"
  "walker/walker         : ~/.config/walker"
  "waybar/waybar         : ~/.config/waybar"
  "wlogout/wlogout       : ~/.config/wlogout"
  "yazi/yazi             : ~/.config/yazi"
  "niri/niri             : ~/.config/niri"

  # ── single-file links (config dir stays real, one file is linked) ──
  "sheldon/plugins.toml               : ~/.config/sheldon/plugins.toml"
  "starship/themes/rose-pine-moon.toml : ~/.config/starship.toml"
  "vscode/code-flags.conf             : ~/.config/code-flags.conf"

  # ── links that go straight to $HOME (not ~/.config) ──
  "git/gitconfig            : ~/.gitconfig"
  "git/gitconfig-work       : ~/.gitconfig-work"
  "git/git-hooks/pre-commit : ~/.git-hooks/pre-commit"
  "tmux.conf                : ~/.tmux.conf"
  "zsh/.p10k.zsh            : ~/.p10k.zsh"
  "vscode/settings.json     : ~/settings.json"

  # ── adopted: repo now holds the current config, symlinked into place ──
  "kitty/kitty             : ~/.config/kitty"
  "fastfetch/fastfetch     : ~/.config/fastfetch"
  "qutebrowser/qutebrowser : ~/.config/qutebrowser"
  "kotofetch/kotofetch     : ~/.config/kotofetch"

  # ── still a real dir, not adopted. Uncomment to adopt (backs up first). ──
  # "matugen/matugen : ~/.config/matugen"
)

# ── helpers ──────────────────────────────────────────────────────────
say()  { printf '%s\n' "$*"; }
run()  { if [[ $DRY_RUN == 1 ]]; then say "   would: $*"; else eval "$@"; fi; }

link_one() {
  local src_rel="$1" dest_raw="$2"
  local src="$DOTFILES/$src_rel"
  local dest="${dest_raw/#\~/$HOME}"

  if [[ ! -e "$src" ]]; then
    say "✗ MISSING in repo: $src_rel  (skipping)"
    return
  fi

  # Already the correct link? nothing to do.
  if [[ -L "$dest" && "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then
    say "✓ ok: $dest"
    return
  fi

  # Something's already there.
  if [[ -e "$dest" || -L "$dest" ]]; then
    # A real directory we don't manage: refuse to clobber.
    if [[ -d "$dest" && ! -L "$dest" ]]; then
      say "⚠ SKIP: $dest is a real directory (not a link). Move it aside"
      say "        manually if you want the repo version to take over."
      return
    fi
    # A real file or a wrong/broken link: back it up, then replace.
    say "↪ backing up existing: $dest"
    run "mkdir -p '$BACKUP_DIR'"
    run "mv '$dest' '$BACKUP_DIR/'"
  fi

  run "mkdir -p '$(dirname "$dest")'"
  run "ln -sfn '$src' '$dest'"
  say "→ linked: $dest -> $src_rel"
}

# ── main ─────────────────────────────────────────────────────────────
say "dotfiles: $DOTFILES"
[[ $DRY_RUN == 1 ]] && say "(dry run — nothing will change)"
say ""

for entry in "${LINKS[@]}"; do
  src="${entry%%:*}"; dest="${entry##*:}"
  # trim surrounding whitespace
  src="$(echo "$src" | xargs)"; dest="$(echo "$dest" | xargs)"
  link_one "$src" "$dest"
done

# ── seed runtime files that are git-ignored (absent on a fresh clone) ──
# kitty.conf does `include current-theme.conf`, but that file is regenerated
# by theme-switch.sh and not tracked. Seed it with the dark theme so kitty
# works on a fresh machine before the first theme switch.
seed_theme="$DOTFILES/kitty/kitty/current-theme.conf"
if [[ ! -e "$seed_theme" ]]; then
  say ""
  run "cp '$DOTFILES/themes/themes/mocha/kitty.conf' '$seed_theme'"
  say "→ seeded: kitty current-theme.conf (dark default)"
fi

say ""
if [[ $DRY_RUN == 0 && -d "$BACKUP_DIR" ]]; then
  say "Anything replaced was backed up to: $BACKUP_DIR"
fi
say "Done."
