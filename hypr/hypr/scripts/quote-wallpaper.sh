#!/usr/bin/env bash
# Quote-of-the-day wallpaper — ASCII-banner card rendered with ImageMagick/Pango,
# Catppuccin Mocha palette, Maple Mono NF, set via swww.
#
#   (default)   pick a RANDOM quote (never the last one), render, set as wallpaper
#   --daily     pick the date-stable "quote of the day" (use this for an auto timer)
#   --force     regenerate the image even if it's already cached
#   --print     render + print the image path, do NOT touch the wallpaper
#
# Quotes live in quotes.txt next to this script — edit that file to curate.

set -euo pipefail
export LC_ALL="${LC_ALL:-C.UTF-8}"   # so ${#str} counts characters, not bytes

SELF="$(realpath "${BASH_SOURCE[0]}")"
HERE="$(dirname "$SELF")"
QUOTES_FILE="$HERE/quotes.txt"
OUTDIR="${XDG_CACHE_HOME:-$HOME/.cache}/quote-wallpaper"
mkdir -p "$OUTDIR"

FONT="Maple Mono NF"
FONTSIZE=30
WRAP=46                # max characters per quote line before wrapping

# ── Catppuccin Mocha ──────────────────────────────────────────────────────────
C_FRAME="#b4befe"      # lavender — the box frame
C_BANNER="#cba6f7"     # mauve    — "QUOTE OF THE DAY"
C_TEXT="#cdd6f4"       # text     — the quote itself
C_AUTHOR="#f9e2af"     # yellow   — author name
C_SHADE="#585b70"      # overlay2 — the ░▒▓ shading bars
C_DATE="#6c7086"       # overlay0 — the date in the bottom rule
BG_CENTER="#232336"    # vignette centre (slightly lifted)
BG_EDGE="#15151f"      # vignette edge   (darker than base #1e1e2e)

FORCE=0 DAILY=0 PRINTONLY=0
for a in "$@"; do case "$a" in
    --force) FORCE=1 ;;
    --daily) DAILY=1 ;;
    --print) PRINTONLY=1 ;;
esac; done

monitor_dims() {
    hyprctl monitors -j 2>/dev/null \
        | jq -r 'max_by(.width*.height) | "\(.width)x\(.height)"' 2>/dev/null \
        || echo "1920x1080"
}

pango_escape() { sed -e 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'; }
rep() { local n=$1 c=$2 s=''; while (( n-- > 0 )); do s+="$c"; done; printf '%s' "$s"; }

# ── pick the quote ────────────────────────────────────────────────────────────
# default: a RANDOM quote, never the one just shown (so re-triggering always
# changes the wallpaper). --daily: date-stable. QOTD_IDX: explicit.
mapfile -t QUOTES < <(grep -vE '^[[:space:]]*#|^[[:space:]]*$' "$QUOTES_FILE")
N=${#QUOTES[@]}
(( N > 0 )) || { echo "no quotes in $QUOTES_FILE" >&2; exit 1; }
IDXFILE="$OUTDIR/.idx"

# ── fzf picker modes ──────────────────────────────────────────────────────────
# --pick  → float a kitty running the menu   --menu → the fzf UI   --qpreview → pane
G_RANDOM=$''   # nf shuffle
G_QUOTE=$''    # nf quote-left
TAB=$'\t'

if [[ "${1:-}" == "--pick" ]]; then
    exec kitty --class quote-picker --title quote-picker -e "$SELF" --menu
fi

if [[ "${1:-}" == "--qpreview" ]]; then
    qi="${2:-0}"
    if [[ "$qi" == "random" ]]; then
        printf '\n  %s  Surprise me\n\n  A random quote, never the one shown last.\n' "$G_RANDOM"
    else
        ql="${QUOTES[qi]}"; printf '\n'; printf '%s\n' "${ql% — *}" | fold -s -w 52 | sed 's/^/  /'
        printf '\n      — %s\n' "${ql##* — }"
    fi
    exit 0
fi

if [[ "${1:-}" == "--menu" ]]; then
    build() {
        printf '%s  Random%s%s\n' "$G_RANDOM" "$TAB" "random"
        for i in "${!QUOTES[@]}"; do
            ql="${QUOTES[i]}"
            printf '%s  %s  (%s)%s%s\n' "$G_QUOTE" "${ql% — *}" "${ql##* — }" "$TAB" "$i"
        done
    }
    sel="$(build | fzf --delimiter="$TAB" --with-nth=1 \
        --layout=reverse --border=rounded --margin=1 --padding=1 \
        --prompt="$G_QUOTE  " --pointer="" --info=inline \
        --header='type to filter — author works too · enter to set as wallpaper' \
        --preview="$SELF --qpreview {2}" \
        --preview-window='down:6:border-top:wrap')" || exit 0
    [[ -z "$sel" ]] && exit 0
    pick="$(cut -f2 <<<"$sel")"
    if [[ "$pick" == "random" ]]; then exec "$SELF"; else exec env QOTD_IDX="$pick" "$SELF"; fi
fi

if [[ -n "${QOTD_IDX:-}" ]]; then idx=$(( QOTD_IDX % N )); echo "$idx" > "$IDXFILE"
elif (( DAILY )); then idx=$(( ($(date +%s) / 86400) % N ))
else
    last=-1; [[ -f "$IDXFILE" ]] && last="$(cat "$IDXFILE" 2>/dev/null || echo -1)"
    idx=$(( RANDOM % N ))
    (( N > 1 )) && while (( idx == last )); do idx=$(( RANDOM % N )); done
    echo "$idx" > "$IDXFILE"
fi
line="${QUOTES[idx]}"
quote="${line% — *}"
author="${line##* — }"
date_str="$(date +%m·%d)"

OUT="$OUTDIR/quote-${idx}.png"   # keyed by quote, so each pick is its own file
if [[ $FORCE == 0 && -f "$OUT" ]]; then
    [[ $PRINTONLY == 1 ]] && { echo "$OUT"; exit 0; }
    SKIP_RENDER=1
fi

if [[ "${SKIP_RENDER:-0}" != 1 ]]; then
# ── lay out the card (plain text first, for exact width math) ──────────────────
mapfile -t qlines < <(printf '%s\n' "$quote" | fold -s -w "$WRAP")
last=$(( ${#qlines[@]} - 1 ))
qlines[0]="\"${qlines[0]}"
qlines[$last]="${qlines[$last]}\""

author_disp="░▒▓ ${author^^} ▓▒░"
header_lbl="┤ QUOTE OF THE DAY ├"
date_lbl=" $date_str "

# content width = widest of: quote lines, author bar, header, date
CW=${#author_disp}
for l in "${qlines[@]}"; do (( ${#l} > CW )) && CW=${#l}; done
(( ${#header_lbl} > CW )) && CW=${#header_lbl}
(( ${#date_lbl}   > CW )) && CW=${#date_lbl}

PAD=3
INTERIOR=$(( PAD + CW + PAD ))   # columns between the two vertical bars

# ── build Pango markup (spans never change column widths) ─────────────────────
sp() { printf '<span foreground="%s">%s</span>' "$1" "$2"; }   # sp COLOR TEXT
{
    printf '<span font="%s %d">' "$FONT" "$FONTSIZE"

    # top rule:  ┌┤ QUOTE OF THE DAY ├────────┐
    fill=$(( INTERIOR - ${#header_lbl} ))
    sp "$C_FRAME" "┌┤ "; sp "$C_BANNER" "QUOTE OF THE DAY"; sp "$C_FRAME" " ├$(rep $fill ─)┐"
    printf '\n'

    blank="$(rep $INTERIOR ' ')"
    row() { sp "$C_FRAME" "│"; printf '%s' "$1"; sp "$C_FRAME" "│"; printf '\n'; }

    row "$blank"
    for l in "${qlines[@]}"; do
        pad_r=$(( CW - ${#l} ))
        body="$(rep $PAD ' ')$(sp "$C_TEXT" "$(printf '%s' "$l" | pango_escape)")$(rep $pad_r ' ')$(rep $PAD ' ')"
        row "$body"
    done
    row "$blank"

    # centred author bar:  ░▒▓ NAME ▓▒░
    name_up="$(printf '%s' "${author^^}" | pango_escape)"
    total_gap=$(( CW - ${#author_disp} ))
    lg=$(( total_gap / 2 )); rg=$(( total_gap - lg ))
    abar="$(rep $((PAD+lg)) ' ')$(sp "$C_SHADE" "░▒▓") $(sp "$C_AUTHOR" "$name_up") $(sp "$C_SHADE" "▓▒░")$(rep $((rg+PAD)) ' ')"
    row "$abar"
    row "$blank"

    # bottom rule:  └────────────────── 06·09 ┘
    fill=$(( INTERIOR - ${#date_lbl} ))
    sp "$C_FRAME" "└$(rep $fill ─)"; sp "$C_DATE" "$date_lbl"; sp "$C_FRAME" "┘"
    printf '\n'

    printf '</span>'
} > "$OUTDIR/.markup"

# ── render: card → drop shadow → composite onto vignette canvas ───────────────
dims="$(monitor_dims)"
magick -background none pango:"@$OUTDIR/.markup" "$OUTDIR/.card.png"

magick "$OUTDIR/.card.png" \
    \( +clone -background black -shadow 55x16+0+10 \) +swap \
    -background none -layers merge +repage "$OUTDIR/.card_sh.png"

magick -size "$dims" "radial-gradient:$BG_CENTER-$BG_EDGE" \
    "$OUTDIR/.card_sh.png" -gravity center -composite "$OUT"

rm -f "$OUTDIR/.markup" "$OUTDIR/.card.png" "$OUTDIR/.card_sh.png"
fi

if [[ $PRINTONLY == 1 ]]; then echo "$OUT"; exit 0; fi

# ── set as wallpaper ──────────────────────────────────────────────────────────
pgrep -x swww-daemon >/dev/null || { swww-daemon & sleep 0.4; }
swww img "$OUT" --transition-type grow --transition-pos 0.5,0.5 \
    --transition-duration 0.8 --transition-fps 60
notify-send "Quote of the day" "$author" 2>/dev/null || true
