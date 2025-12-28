if [[ "$TERM" != "linux" ]]; then
   command -v starship >/dev/null && eval "$(starship init zsh)"
fi 

command -v zoxide   >/dev/null && eval "$(zoxide init zsh)"
command -v fzf      >/dev/null && eval "$(fzf --zsh)"

export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix'

