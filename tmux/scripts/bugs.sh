#!/usr/bin/env bash
c=$(find '/mnt/PERSONAL/Obsidian/Personal/05-Work/Bugs' -maxdepth 1 -type f -name '*.md' ! -name 'README.md' 2>/dev/null | wc -l)
[ "$c" -gt 0 ] && printf $'#[fg=#303030,bg=default]\xee\x82\xb6#[fg=#f9e2af,bg=#303030] \xef\x86\x88  %s #[fg=#303030,bg=default]\xee\x82\xb4 ' "$c"
