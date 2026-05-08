autoload -U compinit && compinit

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu no
zstyle ':fzf-tab:*' fzf-flags --color=fg:4

# bun completions
[ -s "/Users/andre/.bun/_bun" ] && source "/Users/andre/.bun/_bun"

# tock completions
source ~/.zshrc.d/custom/plugins/_tock

# backpack completions
source ~/.zshrc.d/custom/plugins/_backpack
