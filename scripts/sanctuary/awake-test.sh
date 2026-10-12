#!/usr/bin/env bash
# Proves awake.py's hold actually stops the idle lock. Run it, then DON'T touch
# the keyboard or mouse until it prints the result (~25 s). Pauses Brave/mpv/etc.
# for the test and resumes them after.
set -uo pipefail
DIR="$HOME/.dotfiles/scripts/sanctuary"
F=$(mktemp -u)
playing=$(playerctl -a status 2>/dev/null | grep -c Playing)
playerctl -a pause 2>/dev/null
pkill -f "^python3 $DIR/awake.py"
echo "Hands off keyboard + mouse now..."; sleep 3

timeout 8 swayidle timeout 5 "touch $F" 2>/dev/null
[ -f "$F" ] && A=fired || A="did NOT fire"; rm -f "$F"

python3 -c "
import sys,time,importlib.util
s=importlib.util.spec_from_file_location('a',sys.argv[1]);a=importlib.util.module_from_spec(s);s.loader.exec_module(a)
a.Inhibitor().set(True,'test');time.sleep(10)" "$DIR/awake.py" >/dev/null &
sleep 1
timeout 8 swayidle timeout 5 "touch $F" 2>/dev/null
[ -f "$F" ] && B=fired || B="did NOT fire"; rm -f "$F"; wait

setsid -f "$DIR/idle.sh" >/dev/null 2>&1
[ "$playing" -gt 0 ] && playerctl -a play 2>/dev/null

echo "Without hold: idle $A   (should fire)"
echo "With hold:    idle $B   (should NOT fire)"
if [ "$A" = fired ] && [ "$B" = "did NOT fire" ]; then echo "PASS — awake.py works."
elif [ "$A" != fired ]; then echo "INCONCLUSIVE — something else kept you active (input, or another app inhibiting). Try again hands-off."
else echo "FAIL — niri ignored the hold."; fi
