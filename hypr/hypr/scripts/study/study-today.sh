#!/usr/bin/env bash
# Generates today's daily study file (if missing) and opens it in nvim.
# Reads ~/study/phase.md for today's primary subject and ~/study/review-queue.md for due items.

set -euo pipefail

STUDY_DIR="${STUDY_DIR:-$HOME/study}"
DAILY_DIR="$STUDY_DIR/daily"
PHASE="$STUDY_DIR/phase.md"
QUEUE="$STUDY_DIR/review-queue.md"
TODAY="$(date +%Y-%m-%d)"
FILE="$DAILY_DIR/$TODAY.md"

mkdir -p "$DAILY_DIR"

generate() {
    local primary note
    local line
    line="$(grep -E "^$TODAY \|" "$PHASE" || true)"
    if [[ -z "$line" ]]; then
        primary="(no phase entry)"
        note="Add a row to $PHASE"
    else
        primary="$(echo "$line" | awk -F'|' '{gsub(/^ +| +$/,"",$2); print $2}')"
        note="$(echo "$line"    | awk -F'|' '{gsub(/^ +| +$/,"",$3); print $3}')"
    fi

    local due_items
    due_items="$(awk -v today="$TODAY" '
        /^- \[[ x]?\]/ {
            if (match($0, /@next:([0-9]{4}-[0-9]{2}-[0-9]{2})/, m)) {
                if (m[1] <= today) print
            }
        }' "$QUEUE" 2>/dev/null || true)"

    local countdown
    countdown="$(awk -F'|' -v today="$TODAY" '
        /^[0-9]{4}-[0-9]{2}-[0-9]{2}/ {
            d = $1; gsub(/ +$/, "", d);
            note = $3; gsub(/^ +| +$/, "", note);
            if (note ~ /EXAM TODAY/) {
                subj = $2; gsub(/^ +| +$/, "", subj);
                if (d >= today) {
                    cmd = "date -d \"" d "\" +%s"; cmd | getline ts1; close(cmd);
                    cmd = "date -d \"" today "\" +%s"; cmd | getline ts2; close(cmd);
                    days = int((ts1 - ts2) / 86400);
                    if (days == 0)      printf "- **%s** — TODAY\n", subj;
                    else if (days == 1) printf "- **%s** — TOMORROW\n", subj;
                    else                printf "- **%s** — %d days\n", subj, days;
                }
            }
        }' "$PHASE")"

    {
        echo "# $TODAY — $(date +%A)"
        echo
        echo "## Exam countdown"
        if [[ -z "$countdown" ]]; then echo "- (all done)"; else echo "$countdown"; fi
        echo
        echo "## Today's focus"
        echo "**Subject:** $primary"
        echo "**Note:** $note"
        echo
        echo "## Plan (4 Pomodoros = 2 hours, noon–2pm window)"
        echo "- [ ] Pomodoro 1:"
        echo "- [ ] Pomodoro 2:"
        echo "- [ ] Pomodoro 3:"
        echo "- [ ] Pomodoro 4:"
        echo
        echo "## Review (auto-pulled from review-queue.md)"
        if [[ -z "$due_items" ]]; then
            echo "- (nothing due)"
        else
            echo "$due_items"
        fi
        echo
        echo "## Add to review queue (paste into review-queue.md when stable)"
        echo '<!-- - [ ] subject :: topic @next:YYYY-MM-DD @added:'"$TODAY"' -->'
        echo
        echo "## Reflection (1 line, end of day)"
        echo "- "
        echo
        echo "## Notes"
        echo
    } > "$FILE"
}

[[ -f "$FILE" ]] || generate
exec nvim "$FILE"
