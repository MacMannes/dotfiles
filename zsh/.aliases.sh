# Applications
alias vi=nvim
alias gg='lazygit'

# File system
if command -v eza &>/dev/null; then
    alias ls='eza -lh --group-directories-first --icons=auto'
    alias lsa='ls -a'
    alias lrt='ls --sort newest --icons'
    alias lt='eza --tree --level=2 --long --icons --git --git-ignore'
    alias lta='lt -a'
fi

alias ff="fzf --preview 'bat --style=full --color=always {}'"

if which zoxide &>/dev/null; then
    alias cd="zd"
    zd() {
        if [ $# -eq 0 ]; then
            builtin cd ~ && return
        elif [ -d "$1" ]; then
            builtin cd "$1"
        else
            z "$@" && printf "\U000F17A9 " && pwd || echo "Error: Directory not found"
        fi
    }
fi

# Directories
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
