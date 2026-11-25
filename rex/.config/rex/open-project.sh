#!/bin/zsh
# Pick a project folder with fzf and switch to a session named after it, creating
# the session first if it isn't open. Run by the "Open Project" palette action.
# zsh rather than sh so fzf picks up FZF_DEFAULT_OPTS from .zshenv.
set -eu
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"

roots=()
for root in "$HOME/Develop/NS" "$HOME/Develop/MacMannes"; do
    [ -d "$root" ] && roots+=("$root")
done

label=$(find "${roots[@]}" -mindepth 1 -maxdepth 2 -type d -not -name '.*' -not -path '*/posting-ns*' -not -path '*/Attic/*' -not -path '*/node_modules*' 2>/dev/null |
    sed "s|^$HOME|~|" | sort -u | fzf --prompt 'Project: ') || exit 0
dir="$HOME${label#\~}"
name="${dir:t}"

session=$(rex ls --json | jq -r --arg label "$name" '[.sessions[] | select(.label == $label)][0].session_id // empty')
if [ -z "$session" ]; then
    session=$(rex new "$name" -c "$dir" --json | jq -r '.session_id')
fi

"$(dirname "$0")/select-session.sh" "$session" "$name"
