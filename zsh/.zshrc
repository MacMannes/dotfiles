export XDG_CONFIG_HOME="$HOME/.config"

case "$(uname -s)" in
  Darwin) OS=macos ;;
  Linux)  OS=linux ;;
esac

for file in "$HOME/.zshrc.d/os/$OS.zsh" "$HOME/.zshrc.d/"/*.zsh; do
  [[ -r "$file" ]] && source "$file"
done
