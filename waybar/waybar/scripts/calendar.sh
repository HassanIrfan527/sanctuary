#!/bin/bash
# Requires: gcalcli (authenticate on first run with `gcalcli list`)
next=$(gcalcli agenda --nocolor --tsv "now" "today 11:59pm" 2>/dev/null | head -1 | awk -F'\t' '{print $2" "$5}')
[ -z "$next" ] && echo "No events" || echo "$next"
