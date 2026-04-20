gcm() {
    local msg=$(git diff --cached | ollama run llama3.2:latest "Write a concise git commit message for this diff, which could clearly explain what's this commit is about. It should be a one-liner commit message, short, concise and to-the-point. But it should really explain the whole purpose of this commit. No explanation. Just the commit message.")
    echo "Suggested:-\n $msg"
    echo "Edit? (y/n)"
    read confirm
    if [ "$confirm" = "y" ]; then
        git commit -m "$msg"
    fi
}

# explain() {
#     "$@" 2>&1 | ollama run llama3.2:3b "Explain this error in 2-3 sentences and suggest a likely fix:"
# }
#
# japanese() {
#     ollama run qwen2.5:3b "Give me 5 intermediate Japanese vocabulary words with hiragana, romaji, English meaning, and one
#    example sentence each. Format as a table. Pick words appropriate for someone who knows basic JLPT N5 vocab."
# }
