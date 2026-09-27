#!/usr/bin/env bash
# Power menu — fzf in a floating kitty (Mod+Shift+Escape), same idiom as the
# mode picker and the clipboard.
#
# No confirmation and no countdown, on purpose: picking a row IS the decision.
# The safety margin is the order instead — `lock` is the top row, so the cursor
# opens on the harmless action and a stray Enter locks rather than powers off.
# No pointer glyph either: the highlighted row (surface0 fill) is the cursor.
set -uo pipefail

rows=$(cat <<'ROWS'
lock	lock        back in with your password
suspend	suspend     sleep, resume where you left off
logout	log out     quit niri
reboot	reboot      restart now
poweroff	shut down   power off now
ROWS
)

sel=$(printf '%s\n' "$rows" | fzf \
  --no-sort --reverse --border=sharp --no-scrollbar --no-separator \
  --delimiter='\t' --with-nth=2.. \
  --border-label=' power ' --border-label-pos=2 \
  --prompt='  ' --pointer=' ' --marker=' ' --info=hidden \
  --color='bg+:#313244,fg:#a6adc8,fg+:#f5e0dc,hl:#f38ba8,hl+:#f38ba8' \
  --color='border:#96657c,label:#f38ba8,info:#45475a' \
  --color='prompt:#f38ba8,pointer:#f38ba8,spinner:#585b70' \
  --bind 'ctrl-j:down,ctrl-k:up' \
  | cut -f1)

[ -n "$sel" ] || exit 0

# setsid: this kitty exits the moment fzf returns, and anything started from it
# would take the SIGHUP with it (same trap as mode.sh / bar.sh).
#
# Failures are NOT silent. The realistic one: an app holds a logind "shutdown"
# block inhibitor (check with `systemd-inhibit --list`) — systemctl then refuses,
# overriding it needs admin auth, and there is no polkit agent running to ask
# for a password. Without this, "shut down" would just... not, with no trace.
# trap '' HUP: same race mode.sh pick lost — kitty SIGHUPs the pty the moment
# this script exits, and a child that has not reached setsid() yet dies with it.
# An ignored signal survives exec, so the child is immune from its first instant.
act() {
  trap '' HUP
  setsid bash -c '
    out=$("$@" 2>&1) || notify-send -a sanctuary -u critical \
      "Power: $1 $2 failed" "${out:-exit $?} — see: systemd-inhibit --list"
  ' _ "$@" >/dev/null 2>&1 </dev/null &
}

case "$sel" in
  lock)     act loginctl lock-session ;;
  suspend)  act systemctl suspend ;;
  logout)   act niri msg action quit --skip-confirmation ;;
  reboot)   act systemctl reboot ;;
  poweroff) act systemctl poweroff ;;
esac
sleep 0.1
