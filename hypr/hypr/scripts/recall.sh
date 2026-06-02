#!/usr/bin/env bash
# recall.sh — Japanese active-recall, driven entirely by fuzzel popups.
#   question popup (front only) → recall in your head → pick "reveal" →
#   answer popup → self-grade Again/Hard/Good/Easy. Feeds scripts/japanese.py.
#   No due dates: cards ordered by mastery level, hiragana-first.
#   Esc on any popup ends the session.

set -euo pipefail

ENGINE="$HOME/.dotfiles/scripts/japanese.py"
FONT="Maple Mono NF:size=22"   # big enough to read a lone kana/kanji

# one session at a time
exec 9>"/tmp/recall-drawer.lock"
flock -n 9 || exit 0

ask() {  # ask "<prompt>" <lines> -- entries piped on stdin; prints choice
    fuzzel --dmenu \
        --font="$FONT" \
        --prompt="$1   " \
        --width=22 \
        --lines="$2"
}

last=""
while true; do
    card=$(python3 "$ENGINE" next ${last:+--exclude "$last"})
    if [[ "$card" == "{}" || -z "$card" ]]; then
        : | fuzzel --dmenu --font="$FONT" --lines=0 \
            --prompt="おつかれさま · nothing to review   " >/dev/null 2>&1 || true
        break
    fi

    IFS=$'\t' read -r deck key front reading romaji meaning level < <(
        printf '%s' "$card" | python3 -c '
import sys, json
d = json.load(sys.stdin)
print("\t".join([d["deck"], d["key"], d["front"], d["reading"], d["romaji"], d["meaning"], str(d["level"])]))')

    # ── question: front only ──
    if ! choice=$(printf 'reveal\nquit\n' | ask "$front" 2); then
        break
    fi
    [[ "$choice" == "quit" || -z "$choice" ]] && break

    # ── answer + self-grade ──
    answer="$front  →  $reading"
    [[ -n "$romaji" ]] && answer="$answer  ($romaji)"
    [[ -n "$meaning" ]] && answer="$answer   ·   $meaning"
    if ! grade=$(printf 'Again\nHard\nGood\nEasy\nquit\n' | ask "$answer" 5); then
        break
    fi
    case "$grade" in
        Again) q=0 ;;
        Hard)  q=3 ;;
        Good)  q=4 ;;
        Easy)  q=5 ;;
        *)     break ;;
    esac

    python3 "$ENGINE" grade --deck "$deck" --key "$key" -q "$q" >/dev/null
    last="$key"
done
