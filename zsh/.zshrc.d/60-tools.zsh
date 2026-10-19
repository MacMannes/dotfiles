if [[ "$TERM" == "linux" ]]; then
    PS1='%F{green}%n@%m %~ > %f'
else
    command -v starship >/dev/null && eval "$(starship init zsh)"
fi 

command -v zoxide   >/dev/null && eval "$(zoxide init zsh)"
command -v fzf      >/dev/null && eval "$(fzf --zsh)"

export EDITOR='nvim'

export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix'

export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/config"

# yazi wrapper function to change directory on exit
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

