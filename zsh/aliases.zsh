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

# git aliases

alias gs = 'git status'
alias gd = 'git diff'
alias gds = 'git diff --staged'
