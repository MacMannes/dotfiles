export XDG_CONFIG_HOME="$HOME/.config"

case "$(uname -s)" in
  Darwin) OS=macos ;;
  Linux)  OS=linux ;;
esac

for file in "$HOME/.zshrc.d/os/$OS.zsh" "$HOME/.zshrc.d/"/*.zsh; do
  [[ -r "$file" ]] && source "$file"
done

# bun completions
[ -s "/Users/andre/.bun/_bun" ] && source "/Users/andre/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
