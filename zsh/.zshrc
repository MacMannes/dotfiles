export XDG_CONFIG_HOME="$HOME/.config"

case "$(uname -s)" in
  Darwin) OS=macos ;;
  Linux)  OS=linux ;;
esac

for file in "$HOME/.zshrc.d/os/$OS.zsh" "$HOME/.zshrc.d/"/*.zsh; do
  [[ -r "$file" ]] && source "$file"
done



# backpack:completion:start
source "/Users/andre/.config/backpack/completion.zsh"
# backpack:completion:end
# Added by Kiro CLI
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="${PATH:+$PATH:}$HOME/.local/bin" ;; esac
