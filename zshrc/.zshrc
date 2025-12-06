export XDG_CONFIG_HOME="$HOME/.config"

bindkey "^[^[[C" forward-word
bindkey "^[^[[D" backward-word

PATH=/opt/homebrew/bin/:$PATH

alias ls='eza --icons'
eval "$(zoxide init zsh)"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
[ -s "$NVM_DIR" ] && nvm use 22 --silent

[ -s "$HOME/.npm-tokens.sh" ] && \. "$HOME/.npm-tokens.sh"

[ -s "$HOME/.sdkman" ] && source "$HOME/.sdkman/bin/sdkman-init.sh"

export HOMEBREW_NO_ENV_HINT=1

eval "$(starship init zsh)"

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/andre/.lmstudio/bin"

alias vi=nvim

# Created by `pipx` on 2025-03-30 13:49:32
export PATH="$PATH:/Users/andre/.local/bin"

alias lg='lazygit'
