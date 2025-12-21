# Cache Homebrew prefix across shells (macOS only)
if [[ "$OS" == "macos" ]] && command -v brew >/dev/null; then
  if [[ -f ~/.cache/brew_prefix ]]; then
    export HOMEBREW_PREFIX="$(< ~/.cache/brew_prefix)"
  else
    mkdir -p ~/.cache
    HOMEBREW_PREFIX="$(brew --prefix)"
    echo "$HOMEBREW_PREFIX" > ~/.cache/brew_prefix
    export HOMEBREW_PREFIX
  fi

  export PATH="$HOMEBREW_PREFIX/bin:$PATH"
  export HOMEBREW_NO_ENV_HINT=1
fi

