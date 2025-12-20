export XDG_CONFIG_HOME="$HOME/.config"


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

# Autoload completions
autoload -U compinit && compinit

# Antidote package manager
source $HOMEBREW_PREFIX/opt/antidote/share/antidote/antidote.zsh
antidote load

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space # Begin command with a space to hide from history
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu no
# zstyle ':fzf-tab:complete:cd:*' fzf --preview '/bin/ls --color $realpath'
# zstyle ':fzf-tab:complete:__zoxide_z:*' fzf --preview '/bin/ls --color $realpath'


# Keybindings
bindkey "^[^[[C" forward-word
bindkey "^[^[[D" backward-word
bindkey "^[[A" history-beginning-search-backward
bindkey "^[[B" history-beginning-search-forward

# bindkey              '^I' menu-select
# bindkey "$terminfo[kcbt]" menu-select


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" --no-use
[ -s "$HOME/.npm-tokens.sh" ] && \. "$HOME/.npm-tokens.sh"

[ -s "$HOME/.sdkman" ] && source "$HOME/.sdkman/bin/sdkman-init.sh"

export HOMEBREW_NO_ENV_HINT=1

# Shell inttegrations
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
eval "$(fzf --zsh)"

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/andre/.lmstudio/bin"

# Created by `pipx` on 2025-03-30 13:49:32
export PATH="$PATH:/Users/andre/.local/bin"

source ~/.aliases.sh
