# Fastfetch
fastfetch -c ~/.config/fastfetch/config.jsonc

# ~/.zshrc

# User specific environment: update PATH if needed
# Note: Zsh supports POSIX style exports just like Bash
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    PATH="$HOME/.local/bin:${PATH}"
fi
if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
    PATH="$HOME/bin:${PATH}"
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

# Custom Aliases
alias CODE="cd $HOME/Documents/Coding/"
alias app-aie="cd $HOME/Documents/Coding/app-aie"
alias sail="./vendor/bin/sail"
alias manage="cd $HOME/Documents/Coding/Manage"

# Requires kotofetch to be installed and custom quote to be written in the ~/.config/kotofetch/quotes/quotes.toml file
alias quote="kotofetch --modes quotes.toml --source true --translation romaji"
alias keybinds="less ~/.dotfiles/KEYBINDS.md"
alias keybinds-tmux="less ~/.dotfiles/KEYBINDS-TMUX.md"

# source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# zsh-autocomplete must be loaded before other plugins
zstyle ':autocomplete:*' min-input 2
zstyle ':autocomplete:list-choices:*' max-list-choices 0
zstyle ':autocomplete:*' list-lines 8
source $HOME/zsh-autocomplete/zsh-autocomplete.plugin.zsh

source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Starship Initialization
eval "$(starship init zsh)"


# Zoxide Initialization
eval "$(zoxide init zsh)"


# Toggle for zsh-autocomplete




# Keybinds
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char

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

