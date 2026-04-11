#!/usr/bin/env bash
# Prompt for a bug title via fuzzel, then hand it to the `bug` zsh function
# inside a kitty popup. Exits silently on empty/cancelled input.

set -euo pipefail

title=$(: | fuzzel --dmenu --lines=0 --prompt='bug> ' --width=40 || true)

if [[ -z "${title// }" ]]; then
    exit 0
fi

exec kitty \
    --class=bug-capture \
    --title="bug: $title" \
    -e zsh -i -c 'bug "$@"' bug "$title"
