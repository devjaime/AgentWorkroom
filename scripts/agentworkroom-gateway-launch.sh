#!/usr/bin/env bash
set -euo pipefail

# launchd user agents inherit a minimal PATH on macOS.
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/Library/pnpm:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"

# shellcheck source=scripts/agentworkroom-common.sh
source "$(cd -- "$(dirname -- "$0")" && pwd)/agentworkroom-common.sh"

cd "$repo_root"

node_bin=$(command -v node || true)
[ -n "$node_bin" ] || fail "node not found in PATH for launchd runtime"

cmd=("$node_bin" openclaw.mjs gateway run --bind "$AGENTWORKROOM_GATEWAY_BIND" --port "$AGENTWORKROOM_GATEWAY_PORT")
if [ "$AGENTWORKROOM_GATEWAY_FORCE" = "1" ]; then
  cmd+=(--force)
fi

echo $$ > "$AGENTWORKROOM_GATEWAY_PIDFILE"
exec env \
  OPENCLAW_HOME="$OPENCLAW_HOME" \
  OPENCLAW_STATE_DIR="$OPENCLAW_STATE_DIR" \
  OPENCLAW_CONFIG_PATH="$OPENCLAW_CONFIG_PATH" \
  "${cmd[@]}"
