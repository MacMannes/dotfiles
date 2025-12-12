export XDG_CONFIG_HOME="$HOME/.config"

PATH=/opt/homebrew/bin/:$PATH

# Cache Homebrew prefix across shells
if [[ -f ~/.cache/brew_prefix ]]; then
  export HOMEBREW_PREFIX="$(< ~/.cache/brew_prefix)"
else
  mkdir -p ~/.cache
  HOMEBREW_PREFIX="$(brew --prefix)"
  echo "$HOMEBREW_PREFIX" > ~/.cache/brew_prefix
  export HOMEBREW_PREFIX
fi

source $HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $HOMEBREW_PREFIX/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh
source $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh

bindkey "^[^[[C" forward-word
bindkey "^[^[[D" backward-word


alias ls='eza --icons'
eval "$(zoxide init zsh)"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" --no-use
[ -s "$HOME/.npm-tokens.sh" ] && \. "$HOME/.npm-tokens.sh"

[ -s "$HOME/.sdkman" ] && source "$HOME/.sdkman/bin/sdkman-init.sh"

export HOMEBREW_NO_ENV_HINT=1

eval "$(starship init zsh)"

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/andre/.lmstudio/bin"

alias vi=nvim

# Created by `pipx` on 2025-03-30 13:49:32
export PATH="$PATH:/Users/andre/.local/bin"

alias gg='lazygit'
