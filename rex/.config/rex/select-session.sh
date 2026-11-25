#!/bin/sh
# Switch every Rex app attached to this float's session (local or remote, e.g.
# over Tailscale) to a session. Usage: select-session.sh <session-id> <label>
set -u

clients=$(rex api call session.list_clients "{\"session_id\":\"$REX_SESSION\"}" |
    jq -r '.clients[] | select(.info.kind == "app") | .client_id')
failures=""
for client in $clients; do
    error=$(rex -C "$client" do session.select session_id="$1" 2>&1) ||
        failures="$failures\n$client: $error"
done
if [ -n "$failures" ]; then
    printf '\nCould not switch to "%s":%b\nPress Return to close.' "$2" "$failures"
    read -r _
fi
