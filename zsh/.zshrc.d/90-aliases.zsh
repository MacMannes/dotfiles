[[ -f "$HOME/.aliases.sh" ]] && source "$HOME/.aliases.sh"


# In the Rex scratch float (REX_SCRATCH is set by the scratch_float action), close the float after `b`
b() {
    command b "$@"
    local exit_code=$?
    [[ -n "$REX_SCRATCH" ]] && rex block close "$REX_BLOCK" >/dev/null 2>&1
    return $exit_code
}
