# Fastfetch
fastfetch -c ~/.config/fastfetch/config.jsonc

# kotofetch --modes quotes.toml --source true --translation romaji

# ~/.zshrc

# User specific environment: update PATH if needed
# Note: Zsh supports POSIX style exports just like Bash
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    PATH="$HOME/.local/bin:${PATH}"
fi
if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
    PATH="$HOME/bin:${PATH}"
fi
if [[ ":$PATH:" != *":$HOME/.cargo/bin:"* ]]; then
    PATH="$HOME/.cargo/bin:${PATH}"
fi
export PATH

# Uncomment if you don’t like systemctl’s auto-paging
# export SYSTEMD_PAGER=

# Load custom files in ~/.bashrc.d (you can rename directory to ~/.zshrc.d if you like)
if [ -d ~/.zshrc.d ]; then
    for rc in ~/.zshrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc

# Aliases
source ~/.dotfiles/zsh/aliases.zsh

# Utils
source ~/.dotfiles/zsh/utils.zsh

# SE 101 bug capture (bug / bugstats)
source ~/.dotfiles/zsh/bugs.zsh

# Completion system (required before fzf-tab)
autoload -Uz compinit && compinit

# fzf-tab styling
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath 2>/dev/null || ls -1 $realpath'
zstyle ':fzf-tab:*' switch-group '<' '>'

# Starship Initialization
export STARSHIP_CONFIG="$HOME/.config/starship.toml"
eval "$(starship init zsh)"

starship-theme() {
    local themes_dir="$HOME/.dotfiles/starship/themes"
    local theme=$(ls "$themes_dir"/*.toml | xargs -n1 basename -s .toml | fuzzel --dmenu -p "starship theme: ")
    [[ -z "$theme" ]] && return
    ln -sf "$themes_dir/${theme}.toml" "$HOME/.config/starship.toml"
    echo "switched to: $theme"
}

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

# thefuck — corrects the previous command (`fuck`)
eval "$(thefuck --alias)"

# Keybinds (defines widgets + zvm_after_init hook — must precede sheldon)
source ~/.dotfiles/zsh/keybinds.zsh

# zsh-vi-mode: init at source time (prevents recursion with starship prompt)
ZVM_INIT_MODE=sourcing

# Plugins via sheldon (loads zsh-vi-mode, zsh-abbr, zsh-autopair, autocomplete, syntax-highlighting)
eval "$(sheldon source)"

# End of ~/.zshrc

export PATH="$PATH:$HOME/.composer/vendor/bin"

# vapi
export VAPI_INSTALL="$HOME/.vapi"
export PATH="$VAPI_INSTALL/bin:$PATH"
export MANPATH=""$HOME/.vapi"/share/man:$MANPATH"

# opencode
export PATH=/home/anonymous/.opencode/bin:$PATH
export PATH="$HOME/.npm-global/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export EDITOR=nvim
export VISUAL=nvim

export PATH="$HOME/go/bin:$PATH"
export GI_TYPELIB_PATH="/usr/local/lib64/girepository-1.0:$GI_TYPELIB_PATH"
