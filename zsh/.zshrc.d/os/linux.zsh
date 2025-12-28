# Antidote via system packages
if [[ -f /usr/share/zsh-antidote/antidote.zsh ]]; then
  source /usr/share/zsh-antidote/antidote.zsh
fi

if [[ "$TERM" == "linux" ]]; then
    export STARSHIP_CONFIG="$HOME/.config/starship/starship-tty.toml"
else
    export STARSHIP_CONFIG="$HOME/.config/starship.toml"
fi
