HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt share_history hist_ignore_dups

autoload -Uz compinit && compinit
PROMPT='%F{cyan}%n@%m%f %F{yellow}%~%f %# '

alias fd=fdfind
