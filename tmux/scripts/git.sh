#!/bin/sh
# Print git branch + dirty flag for the active pane's path.
# Discovers the path itself via tmux, since #{pane_current_path}
# expansion inside #() is unreliable across tmux versions.
path="${1:-$(tmux display-message -p '#{pane_current_path}' 2>/dev/null)}"
[ -z "$path" ] && exit 0
cd "$path" 2>/dev/null || exit 0
branch=$(git symbolic-ref --short HEAD 2>/dev/null || git describe --tags --exact-match 2>/dev/null)
[ -z "$branch" ] && exit 0
if git diff --quiet 2>/dev/null && git diff --cached --quiet 2>/dev/null; then
  printf '%s' "$branch"
else
  printf '%s*' "$branch"
fi
