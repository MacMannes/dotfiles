# Antidote via Homebrew
if [[ -n "$HOMEBREW_PREFIX" ]] &&
   [[ -f "$HOMEBREW_PREFIX/opt/antidote/share/antidote/antidote.zsh" ]]; then
  source "$HOMEBREW_PREFIX/opt/antidote/share/antidote/antidote.zsh"
fi

# LM Studio
export PATH="$PATH:$HOME/.lmstudio/bin"

