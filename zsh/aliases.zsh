# Laravel
alias sail="./vendor/bin/sail"

# Quotes & docs
# alias quote="kotofetch --modes quotes.toml --source true --translation romaji"
alias keybinds="less ~/.dotfiles/KEYBINDS.md"
alias keybinds-tmux="less ~/.dotfiles/KEYBINDS-TMUX.md"

# Television
alias tvf='tv files'
alias tvt='tv text'
alias tvg='tv git-log'
alias tvb='tv git-branch'
alias tve='tv env'
alias tva='tv alias'

# fun aliases
alias void='sudo dnf'

alias work-on='sudo tailscale up && echo "🔓 Tailscale UP — work DNS + hostnames active"'
alias work-off='sudo tailscale down && echo "🔒 Tailscale DOWN — encrypted Mullvad DNS active"'

# quick check: where is my DNS going right now?
alias dns-check='resolvectl query --cache=no example.com 2>&1 | grep -i "encrypted transport"'

# harlequin db connection aliases
htdb() {
    if [ -z "$POSTGRES_TEST_CONNECTION_STRING" ]; then
        echo "Error: Connection string not found."
        return 1
    fi
    harlequin -a postgres "$POSTGRES_TEST_CONNECTION_STRING" "$@"
}

hpdb() {
    if [ -z "$POSTGRES_PROD_CONNECTION_STRING" ]; then
        echo "Error: Connection string not found."
        return 1
    fi
    harlequin -a postgres "$POSTGRES_PROD_CONNECTION_STRING" "$@"
}
