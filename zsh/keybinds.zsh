# Note: zsh-vi-mode handles `bindkey -v` and KEYTIMEOUT on its own.

# fzf key bindings (Ctrl+R history, Ctrl+T files, Alt+C cd)
source /usr/share/fzf/shell/key-bindings.zsh

# Insert mode — keep familiar terminal keys working
bindkey -M viins '^[[1;5C' forward-word
bindkey -M viins '^[[1;5D' backward-word
bindkey -M viins '^[[H'    beginning-of-line
bindkey -M viins '^[[F'    end-of-line
bindkey -M viins '^[[3~'   delete-char

# television widgets
_tv_files_widget()     { local s; s=$(tv files      </dev/tty); [[ -n $s ]] && LBUFFER+="$s"; zle reset-prompt; }
_tv_text_widget()      { local s; s=$(tv text       </dev/tty); [[ -n $s ]] && LBUFFER+="$s"; zle reset-prompt; }
_tv_gitlog_widget()    { local s; s=$(tv git-log    </dev/tty); [[ -n $s ]] && LBUFFER+="$s"; zle reset-prompt; }
_tv_gitbranch_widget() { local s; s=$(tv git-branch </dev/tty); [[ -n $s ]] && LBUFFER+="$s"; zle reset-prompt; }
zle -N _tv_files_widget
zle -N _tv_text_widget
zle -N _tv_gitlog_widget
zle -N _tv_gitbranch_widget

# Leader bindings live inside zvm_after_init so they survive
# zsh-vi-mode's keymap re-init after each command.
function zvm_after_init() {
  bindkey -M vicmd -r ' '

  # fzf leaders
  bindkey -M vicmd ' f' fzf-file-widget       # Space f  → fuzzy files
  bindkey -M vicmd ' h' fzf-history-widget    # Space h  → fuzzy history
  bindkey -M vicmd ' j' fzf-cd-widget         # Space j  → fuzzy cd (jump)

  # television leaders (Space + t + <x>)
  bindkey -M vicmd ' tf' _tv_files_widget     # Space t f → tv files
  bindkey -M vicmd ' tt' _tv_text_widget      # Space t t → tv text (grep)
  bindkey -M vicmd ' tg' _tv_gitlog_widget    # Space t g → tv git-log
  bindkey -M vicmd ' tb' _tv_gitbranch_widget # Space t b → tv git-branch

  # Initial mode sync to tmux status bar
  if [[ -n $TMUX ]]; then
    tmux set -g @zvm_mode "INSERT"
    tmux set -g @zvm_mode_color "#80a0ff"
  fi
}

# Sync mode changes to tmux status bar (bubbles theme)
function zvm_after_select_vi_mode() {
  [[ -z $TMUX ]] && return
  case $ZVM_MODE in
    $ZVM_MODE_NORMAL)       tmux set -g @zvm_mode "NORMAL";  tmux set -g @zvm_mode_color "#d183e8" ;;
    $ZVM_MODE_INSERT)       tmux set -g @zvm_mode "INSERT";  tmux set -g @zvm_mode_color "#80a0ff" ;;
    $ZVM_MODE_VISUAL)       tmux set -g @zvm_mode "VISUAL";  tmux set -g @zvm_mode_color "#79dac8" ;;
    $ZVM_MODE_VISUAL_LINE)  tmux set -g @zvm_mode "V-LINE";  tmux set -g @zvm_mode_color "#79dac8" ;;
    $ZVM_MODE_REPLACE)      tmux set -g @zvm_mode "REPLACE"; tmux set -g @zvm_mode_color "#ff5189" ;;
  esac
  tmux refresh-client -S
}
