# SE 101 bug capture — pull-based, terminal-native, zero friction.
# `bug <title...>`  creates/opens a dated note in the vault's Bugs folder.
# `bugstats`        prints counts and top title keywords.

export SE101_VAULT="/mnt/PERSONAL/Obsidian/SE 101"
export SE101_BUGS="$SE101_VAULT/Bugs"

bug() {
    if [[ $# -eq 0 ]]; then
        print -u2 "usage: bug <title...>"
        return 1
    fi

    local title="$*"
    local today
    today=$(date +%Y-%m-%d)

    local slug
    slug=$(print -r -- "$title" \
        | tr '[:upper:]' '[:lower:]' \
        | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')

    if [[ -z "$slug" ]]; then
        print -u2 "bug: title produced empty slug, aborting"
        return 1
    fi

    mkdir -p "$SE101_BUGS" || return 1
    local file="$SE101_BUGS/${today}_${slug}.md"

    if [[ ! -e "$file" ]]; then
        cat > "$file" <<EOF
# $title

**Date**: $today
**Status**: investigating

## Symptom
<!-- what did you see happen -->

## Investigation
<!-- what did you check, what did you rule out -->

## Root cause
<!-- the actual reason -->

## Fix
<!-- what worked or would work -->

## Notes
<!-- anything you learned about the system -->
EOF
    fi

    ${EDITOR:-nvim} "$file"
}

bugstats() {
    if [[ ! -d "$SE101_BUGS" ]]; then
        print "no bugs captured yet ($SE101_BUGS missing)"
        return 0
    fi

    local total recent
    total=$(find "$SE101_BUGS" -maxdepth 1 -type f -name '*.md' ! -name 'README.md' 2>/dev/null | wc -l)
    recent=$(find "$SE101_BUGS" -maxdepth 1 -type f -name '*.md' ! -name 'README.md' -mtime -7 2>/dev/null | wc -l)

    printf "total:   %s\nlast 7d: %s\n\n" "$total" "$recent"

    if (( total > 0 )); then
        print "top title keywords:"
        find "$SE101_BUGS" -maxdepth 1 -type f -name '*.md' ! -name 'README.md' -printf '%f\n' 2>/dev/null \
            | sed -E 's/^[0-9]{4}-[0-9]{2}-[0-9]{2}_//; s/\.md$//; s/-/\n/g' \
            | grep -vxE '(the|a|an|and|or|of|to|in|on|for|is|with|at)' \
            | grep -vE '^$' \
            | sort | uniq -c | sort -rn | head -5
    fi
}
