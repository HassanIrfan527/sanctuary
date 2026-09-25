#!/usr/bin/env bash
# RETIRED 2026-09-22 — NOT BOUND TO ANYTHING. The launcher is walker now.
#
# Harry ran this and turned it down: "no i dont like the terminal one. just
# use walker... we're overcomplicating things." The objection was not the look
# — it was that a terminal launcher is a lot of machinery for a launcher.
# See DESIGN-BRIEF.md §3, and §5 for what replaced it.
#
# Kept on disk, unbound, on the same reasoning as the mako config kept beside
# swaync: the work is done and costs nothing sitting here, and the four fzf
# traps documented below still apply to clipboard.sh, which is still fzf.
# Delete it whenever it stops feeling like a useful reference.
#
# ── original header ──────────────────────────────────────────────────────
# The launcher — desktop entries through fzf in a floating kitty.
#
#   run.sh          spawn the launcher window (what Mod+Space calls)
#   run.sh menu     the UI itself; runs inside the kitty window
#   run.sh index    print the entry index to stdout (debugging)
#
# WHY A TERMINAL AND NOT FUZZEL
# fuzzel's layout is compiled in: prompt row, input row, list rows, nothing
# else. No header, no frame glyphs, no per-row prefix, no preview. `[ run ]`
# was its entire ASCII budget and it was already spent — so the launcher could
# not be pushed any further by configuration. Meanwhile every surface here that
# reads as ASCII (clipboard.sh, wallpaper.sh, wiremix) is a TUI in a floating
# kitty, where the text *is* the UI. The launcher was the last layer-shell
# widget, which is exactly why it was the one that looked wrong.
# DESIGN-BRIEF.md §5 already named this as the fallback "if it starts to
# grate". It grated.
#
# Bonus: a real window means niri animates it, which was the original
# objection to a terminal launcher back when layer-shell surfaces were the
# thing that could not be animated. That reason inverted.
#
# FUZZEL IS NOT REMOVED. fuzzel/fuzzel/fuzzel.ini is untouched and
# Mod+Shift+Space still opens it — same arrangement as the mako config kept
# beside swaync. The way back is one keypress, not a file edit.
set -uo pipefail

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/sanctuary"
HIST="$STATE/run-history"
SELF="$(readlink -f "$0")"
mkdir -p "$STATE"

# ── Mocha, straight from DESIGN-BRIEF.md §4 ──────────────────────────────
crust=#11111b; surface0=#313244; surface1=#45475a
overlay0=#6c7086; subtext0=#a6adc8; text=#cdd6f4
lavender=#b4befe; mauve=#cba6f7
# The launcher's own border tone, carried over from fuzzel.ini so the surface
# keeps its identity across the swap. Brighter than the bar's muted borders on
# purpose: this is the one surface read while tired.
bord=#8b92b8

# bash arithmetic needs the 16# form for hex; do the conversion here once.
fg() { local h=${1#\#}; printf '\033[38;2;%d;%d;%dm' "$((16#${h:0:2}))" "$((16#${h:2:2}))" "$((16#${h:4:2}))"; }
RST=$'\033[0m'

NAMEW=22   # name column; the rest of the row is the subtitle

# ── The entry index ──────────────────────────────────────────────────────
# One awk pass over every .desktop file. No cache: 44 files in a single
# process is a few milliseconds, and a cache would only buy staleness bugs.
#
# Each output line is  sortkey \t display \t mode:payload
#   display  is what fzf shows AND what it searches, so the keywords have to
#            live inside it — see the note on invisible text below.
#   mode     g = gio launch (desktop entry, handles field codes + DBus
#            activation), t = run in a terminal, x = run directly (actions).
build_index() {
  local dirs=() d
  # XDG_DATA_DIRS is colon-separated; split it rather than globbing it.
  local _dd; IFS=':' read -r -a _dd <<< "${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
  dirs=("${XDG_DATA_HOME:-$HOME/.local/share}/applications")
  for d in "${_dd[@]}"; do [ -n "$d" ] && dirs+=("$d/applications"); done

  local files=()
  local -A seen=()
  local f id
  # Earlier directories win, which is how XDG precedence works: a user
  # override in ~/.local/share shadows the system copy of the same ID.
  for d in "${dirs[@]}"; do
    [ -d "$d" ] || continue
    for f in "$d"/*.desktop; do
      [ -f "$f" ] || continue
      id=${f##*/}
      [ -n "${seen[$id]:-}" ] && continue
      seen[$id]=1
      files+=("$f")
    done
  done
  [ ${#files[@]} -gt 0 ] || return 0

  awk -v HIST="$HIST" -v NAMEW="$NAMEW" \
      -v C_TEXT="$(fg $text)" -v C_DIM="$(fg $overlay0)" -v C_HIDE="$(fg $crust)" \
      -v RST=$'\033[0m' '
  function flush() {
    if (path == "" || type != "Application" || nodisplay || hidden) return
    if (exec_ != "") {
      mode = (term ? "t:" cmd(exec_) : "g:" path)
      # GenericName only, never Comment. fuzzel.ini already settled this with
      # fields=name,generic,keywords: Comment matches far too loosely and
      # pushes the thing you meant down the list. It is also what made
      # "discord" match Blender here — a 130-character keyword blob and a
      # sentence-long Comment give a fuzzy subsequence somewhere to hide.
      # An entry with no GenericName gets no subtitle, which is just the
      # empty-states-render-nothing rule of §2 applied to a column.
      row(name, generic, keywords, mode)
    }
    # Desktop-entry actions ("New Private Window", "Preferences"). fuzzel had
    # show-actions=yes; this keeps that. gio launch cannot target an action,
    # so these are exec-ed directly.
    n = split(actions, A, ";")
    for (i = 1; i <= n; i++) {
      a = A[i]
      if (a == "" || !(a in aexec)) continue
      # The app name stays in the name column and the action rides in the
      # subtitle. Putting them both in the name column truncated the action
      # away entirely ("Brave Web Browser · …"), which made the row useless.
      row(name, "▸ " (a in aname ? aname[a] : a), "", "x:" cmd(aexec[a]))
    }
  }
  # Strip Exec field codes. %f %F %u %U %i %c %k all expect something we do
  # not have (a file, an icon, a name) and leave literal junk in argv if kept.
  function cmd(e) {
    gsub(/%[fFuUickvmdDnNU]/, "", e)
    gsub(/  +/, " ", e)
    sub(/ +$/, "", e)
    return e
  }
  function row(nm, sub_, kw, payload) {
    key = payload
    rank = 999999999 - (key in CNT ? CNT[key] : 0)
    disp = nm
    if (length(disp) > NAMEW - 1) disp = substr(disp, 1, NAMEW - 2) "…"
    pad = NAMEW - length(disp); if (pad < 1) pad = 1
    line = C_TEXT disp sprintf("%" pad "s", "") C_DIM sub_
    # Keywords have to be matchable, and fzf only searches what it DISPLAYS —
    # --with-nth hides a field from the search as well, verified. So they ride
    # along inside the visible field, parked past a wide run of spaces so they
    # land far outside the window and are never drawn. Painting them crust-on-
    # crust was the first attempt and it leaked: fzf horizontal-scrolls to a
    # match, which dragged them into view and pushed the app name off the left
    # edge ("esktop" instead of "Vesktop"). --no-hscroll plus this padding is
    # the fix. It is why typing "discord" finds Vesktop and "mixer" finds
    # pavucontrol, with nothing visible to show for it.
    if (kw != "") {
      gsub(/;/, " ", kw)
      # NOT capped. Capping these at 80 characters was tried and reverted:
      # pavucontrol lists "Mixer" at character 110, so the cap was what
      # stopped "mixer" from finding Volume Control. Dropping Comment was
      # the change that actually cut the noise; the cap only cut recall.
      line = line SP kw
    }
    printf "%09d\t%s\t%s\t%s\n", rank, tolower(nm), line RST, payload
  }
  function reset() {
    path = ""; name = ""; generic = ""; comment = ""; keywords = ""
    exec_ = ""; type = ""; actions = ""; term = 0; nodisplay = 0; hidden = 0
    section = ""; aid = ""
    split("", aexec); split("", aname)
  }
  BEGIN {
    while ((getline l < HIST) > 0) { split(l, p, "\t"); CNT[p[1]] = p[2] + 0 }
    close(HIST)
    SP = sprintf("%160s", "")
    reset()
  }
  FNR == 1 { flush(); reset(); path = FILENAME }
  /^[ \t]*[#;]/ { next }
  /^\[/ {
    if ($0 ~ /^\[Desktop Entry\]/)        { section = "entry" }
    else if ($0 ~ /^\[Desktop Action /)   { section = "action"
                                            aid = $0
                                            sub(/^\[Desktop Action[ \t]*/, "", aid)
                                            sub(/\][ \t]*$/, "", aid) }
    else                                  { section = "other" }
    next
  }
  {
    eq = index($0, "="); if (eq == 0) next
    k = substr($0, 1, eq - 1); v = substr($0, eq + 1)
    gsub(/[ \t]+$/, "", k); gsub(/^[ \t]+/, "", v); gsub(/[ \t]+$/, "", v)
    # Skip localised keys — Name[de] must not overwrite Name.
    if (k ~ /\[/) next
    if (section == "entry") {
      if      (k == "Name"        && name    == "") name    = v
      else if (k == "GenericName" && generic == "") generic = v
      else if (k == "Comment"     && comment == "") comment = v
      else if (k == "Keywords"    && keywords== "") keywords= v
      else if (k == "Exec"        && exec_   == "") exec_   = v
      else if (k == "Type"        && type    == "") type    = v
      else if (k == "Actions"     && actions == "") actions = v
      else if (k == "Terminal")   term      = (v == "true")
      else if (k == "NoDisplay")  nodisplay = (v == "true")
      else if (k == "Hidden")     hidden    = (v == "true")
    } else if (section == "action" && aid != "") {
      if      (k == "Name" && !(aid in aname)) aname[aid] = v
      else if (k == "Exec" && !(aid in aexec)) aexec[aid] = v
    }
  }
  END { flush() }
  ' "${files[@]}" | sort -t$'\t' -k1,1 -k2,2 | cut -f3-
}

# ── The banner ───────────────────────────────────────────────────────────
# Static text and three cheap reads, all at open time. Nothing polls, so this
# costs no resident process — the constraint DESKTOP-PLAN.md §1 puts on every
# module that wants to exist on an i5-6500.
banner() {
  local count=$1 secs h m up load
  secs=${EPOCHSECONDS:-0}
  read -r secs _ < /proc/uptime; secs=${secs%.*}
  h=$((secs / 3600)); m=$(((secs % 3600) / 60)); up="${h}h ${m}m"
  read -r load _ < /proc/loadavg
  local L R
  L=$(fg $lavender); R=$(fg $overlay0)
  # fzf already indents the header by the gutter+pointer columns, so the
  # banner carries none of its own. Labels left, values in one column.
  printf '%s█▀▄ █ █ █▄ █   %sapps %s\n' "$L" "$R" "$count"
  printf '%s█▀▄ █ █ █ ▀█   %sup   %s\n' "$L" "$R" "$up"
  printf '%s▀ ▀ ▀▀▀ ▀  ▀   %sload %s%s\n' "$L" "$R" "$load" "$RST"
}

# ── The UI ───────────────────────────────────────────────────────────────
menu() {
  local index sel mode payload
  index=$(build_index)
  [ -n "$index" ] || exit 0

  sel=$(printf '%s\n' "$index" | fzf \
    --ansi --delimiter=$'\t' --with-nth=1 --accept-nth=2 \
    --layout=reverse --header-first \
    --header="$(banner "$(printf '%s\n' "$index" | grep -c '')")" \
    --border=sharp --border-label=' the sanctuary ' --border-label-pos=2 \
    --prompt='[ run ] ' --ghost='filter' --pointer='█' --marker=' ' \
    --header-border=bottom \
    --info=inline-right --ellipsis='' --cycle --tiebreak=begin,length \
    --no-separator --no-hscroll --gutter='░' --scrollbar='█' \
    --color="bg:$crust,bg+:$surface0,fg:$subtext0,fg+:$text,gutter:-1" \
    --color="hl:$mauve,hl+:$mauve,prompt:$lavender,pointer:$lavender" \
    --color="border:$bord,label:$lavender,separator:$surface1" \
    --color="info:$surface1,ghost:$surface1,scrollbar:$surface1,query:$text" \
    --bind 'ctrl-j:down,ctrl-k:up,ctrl-u:clear-query' \
    --bind 'esc:abort') || exit 0
  [ -n "$sel" ] || exit 0

  mode=${sel%%:*}
  payload=${sel#*:}

  # Remember it, so the next open puts it back near the top. This is the one
  # thing fuzzel gave for free (sort-result reads its own launch cache) and
  # the launcher would be worse without it — §1 says one keypress, and muscle
  # memory only works if the order is stable.
  bump "$sel"

  # setsid, always: the app must outlive this kitty window. Without it the
  # launcher cannot close until the app does. Same lesson as wl-copy in
  # clipboard.sh, different symptom.
  case "$mode" in
    g) setsid gio launch "$payload" >/dev/null 2>&1 & ;;
    t) setsid kitty -e sh -c "$payload" >/dev/null 2>&1 & ;;
    x) setsid sh -c "$payload" >/dev/null 2>&1 & ;;
  esac
  disown 2>/dev/null || true
}

bump() {
  local key=$1 tmp
  tmp=$(mktemp "$STATE/.run-history.XXXXXX") || return 0
  awk -v K="$key" -F'\t' '
    BEGIN { OFS = "\t" }
    $1 == K { print $1, $2 + 1; hit = 1; next }
    NF      { print }
    END     { if (!hit) print K, 1 }
  ' "$HIST" 2>/dev/null > "$tmp" || { rm -f "$tmp"; return 0; }
  mv -f "$tmp" "$HIST"
}

case "${1:-pick}" in
  menu)  menu ;;
  index) build_index | cat -v ;;
  pick)
    # Size is set in CELLS, not pixels, and therefore here rather than in the
    # niri window-rule: the drawn frame has to land on exact character
    # boundaries or the box corners get clipped. niri honours a floating
    # window's own requested size, so kitty's initial_window_* wins.
    #
    # Padding 0 and niri's border off (window-rules.kdl) leave the fzf frame
    # as the only border. Two nested borders 8px apart is noise; one island,
    # one border — DESIGN-BRIEF.md §2.
    #
    # --config NONE skips kitty.conf entirely, and it is load-bearing twice
    # over. It is worth ~85ms of the open (302ms -> 217ms measured), because
    # the launcher was otherwise loading Maple Mono, the Symbols Nerd Font
    # fallbacks, the powerline tab bar and background_blur for a surface that
    # sets all its own colours anyway. It also pins the look: nothing you
    # change in the terminal theme later can leak in here.
    #
    # The catch: skipping the config also skips `remember_window_size no`,
    # and kitty's own default is `yes`, which makes it ignore
    # initial_window_* and restore whatever size it saw last. That is why the
    # window came back 942x1012 instead of 641x438 the first time. Both have
    # to be passed together.
    exec kitty --config NONE --class sanctuary-run \
      --override remember_window_size=no \
      --override font_family="JetBrainsMono Nerd Font" \
      --override bold_font="JetBrainsMono Nerd Font Bold" \
      --override font_size=13 \
      --override initial_window_width=64c \
      --override initial_window_height=19c \
      --override window_padding_width=0 \
      --override background="$crust" \
      --override background_opacity=1 \
      --override cursor_trail=0 \
      --override confirm_os_window_close=0 \
      -e "$SELF" menu
    ;;
esac
