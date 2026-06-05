gcm() {
    local diff=$(git diff --cached)
    if [ -z "$diff" ]; then
        echo "Nothing staged."
        return 1
    fi

    # Cap input at ~5KB to keep it fast
    local truncated=$(echo "$diff" | head -c 5000)

    local msg=$(echo "$truncated" | ollama run llama3.2:1b \
        "Write a git commit message. ONE subject line under 60 characters, imperative mood. No explanation, no code review.
   Just the message.")

    echo "Suggested: $msg"
    echo "Commit? (y/n)"
    read -r confirm
    [ "$confirm" = "y" ] && git commit -m "$msg"
}

# y: open yazi, then cd to wherever you ended up when you quit (q).
# Use `Q` inside yazi to quit WITHOUT cd-ing.
y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

# explain() {
#     "$@" 2>&1 | ollama run llama3.2:3b "Explain this error in 2-3 sentences and suggest a likely fix:"
# }
#
# japanese() {
#     ollama run qwen2.5:3b "Give me 5 intermediate Japanese vocabulary words with hiragana, romaji, English meaning, and one
#    example sentence each. Format as a table. Pick words appropriate for someone who knows basic JLPT N5 vocab."
# }
