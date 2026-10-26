# Shared settings first; personal overrides in ~/.extra are loaded last.
for dotfile in "$HOME/.exports" "$HOME/.path"; do
    [[ -r $dotfile ]] && source "$dotfile"
done
unset dotfile

HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
mkdir -p "${HISTFILE:h}"
HISTSIZE=50000
SAVEHIST=50000
setopt APPEND_HISTORY EXTENDED_HISTORY HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE HIST_REDUCE_BLANKS SHARE_HISTORY
setopt AUTO_CD INTERACTIVE_COMMENTS
KEYTIMEOUT=10

# Keep the original steeef theme and vi editing.
for zsh_root in "$HOME/.oh-my-zsh" "${XDG_DATA_HOME:-$HOME/.local/share}/oh-my-zsh" /usr/share/oh-my-zsh; do
    if [[ -r $zsh_root/oh-my-zsh.sh ]]; then
        export ZSH="$zsh_root"
        break
    fi
done
unset zsh_root
ZSH_THEME=steeef
zstyle ':omz:update' mode disabled
plugins=(git vi-mode)
(( $+commands[go] )) && plugins+=(golang)
(( $+commands[ruby] )) && plugins+=(ruby)
(( $+commands[pass] )) && plugins+=(pass)
if [[ -r ${ZSH:-}/oh-my-zsh.sh ]]; then
    source "$ZSH/oh-my-zsh.sh"
else
    autoload -Uz compinit colors vcs_info
    compinit -d "${HISTFILE:h}/zcompdump"
    colors
    zstyle ':vcs_info:git:*' formats ' (%b)'
    precmd() { vcs_info; }
    setopt PROMPT_SUBST
    PROMPT='%F{cyan}%n@%m%f %F{green}%~%f${vcs_info_msg_0_} %# '
fi
bindkey -v

# User aliases take precedence over framework aliases.
for dotfile in "$HOME/.aliases" "$HOME/.functions" "$HOME/.dockerfunc"; do
    [[ -r $dotfile ]] && source "$dotfile"
done
unset dotfile

# Keep the desktop SSH agent; only update the GPG terminal when real.
if [[ -t 0 ]] && (( $+commands[gpg-connect-agent] )); then
    export GPG_TTY="$(tty)"
    gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
fi

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [[ -r $NVM_DIR/nvm.sh ]]; then
    source "$NVM_DIR/nvm.sh"
elif [[ -r /usr/share/nvm/init-nvm.sh ]]; then
    source /usr/share/nvm/init-nvm.sh
fi
[[ -r $HOME/.rvm/scripts/rvm ]] && source "$HOME/.rvm/scripts/rvm"
if [[ -t 0 && -o zle ]] && (( $+commands[fzf] )); then
    source <(fzf --zsh)
fi

[[ -r $HOME/.extra ]] && source "$HOME/.extra"

# Syntax highlighting must be the last plugin loaded.
[[ -r /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] &&
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
true
