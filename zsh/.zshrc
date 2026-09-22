zmodload zsh/zprof

# ~/.zshrc

if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    PATH="$HOME/.local/bin:${PATH}"
fi
if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
    PATH="$HOME/bin:${PATH}"
fi

export PATH

# Load custom files in ~/.bashrc.d
if [ -d ~/.zshrc.d ]; then
    for rc in ~/.zshrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc

# Completion system (required before fzf-tab)
autoload -Uz compinit && compinit

# fzf-tab styling
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath 2>/dev/null || ls -1 $realpath'
zstyle ':fzf-tab:*' switch-group '<' '>'

# Starship Initialization
export STARSHIP_CONFIG="$HOME/.config/starship.toml"
eval "$(starship init zsh)"

# Zoxide Initialization
eval "$(zoxide init zsh)"

# Direnv Initialization
eval "$(direnv hook zsh)"

# Toggle for zsh-autocomplete

# History
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE HIST_REDUCE_BLANKS
setopt SHARE_HISTORY INC_APPEND_HISTORY

# Skip secrets from history
zshaddhistory() {
    emulate -L zsh
    if [[ $1 == *(TOKEN|SECRET|PASSWORD|API_KEY|PRIVATE_KEY|BEARER|Authorization)* ]]; then
        return 1
    fi
    return 0
}

# Navigation
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT
setopt INTERACTIVE_COMMENTS

# zsh-vi-mode: init at source time (prevents recursion with starship prompt)
export ZVM_INIT_MODE=sourcing

# Plugins via sheldon (loads zsh-vi-mode, zsh-abbr, zsh-autopair, autocomplete, syntax-highlighting)
eval "$(sheldon source)"

export PATH="$HOME/.config/composer/vendor/bin:$PATH"

export MANPATH=""$HOME/.vapi"/share/man:$MANPATH"

export PATH="$HOME/.npm-global/bin:$PATH"
export EDITOR=nvim
export VISUAL=nvim

export PATH="$HOME/go/bin:$PATH"

echo 'eval "$(atuin init zsh)"' >>~/.zshrc
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
eval "$(atuin init zsh)"
