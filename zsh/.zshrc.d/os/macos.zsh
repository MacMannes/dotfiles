# Cache Homebrew prefix across shells
if [[ -f ~/.cache/brew_prefix ]]; then
  export HOMEBREW_PREFIX="$(< ~/.cache/brew_prefix)"
else
  mkdir -p ~/.cache
  HOMEBREW_PREFIX="$(brew --prefix)"
  echo "$HOMEBREW_PREFIX" > ~/.cache/brew_prefix
  export HOMEBREW_PREFIX
fi

PATH=${HOMEBREW_PREFIX}/bin/:$PATH

# Antidote via Homebrew
if [[ -n "$HOMEBREW_PREFIX" ]] &&
   [[ -f "$HOMEBREW_PREFIX/opt/antidote/share/antidote/antidote.zsh" ]]; then
  source "$HOMEBREW_PREFIX/opt/antidote/share/antidote/antidote.zsh"
fi

# LM Studio
export PATH="$PATH:$HOME/.lmstudio/bin"

