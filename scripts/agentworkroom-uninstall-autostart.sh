#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/agentworkroom-common.sh
source "$(cd -- "$(dirname -- "$0")" && pwd)/agentworkroom-common.sh"

launchctl bootout "$(launchctl_domain)" "$AGENTWORKROOM_LAUNCHD_PLIST" >/dev/null 2>&1 || true
launchctl disable "$(launchctl_service_target)" >/dev/null 2>&1 || true

if [ -f "$AGENTWORKROOM_LAUNCHD_PLIST" ]; then
  rm -f "$AGENTWORKROOM_LAUNCHD_PLIST"
  info "Removed autostart LaunchAgent: $AGENTWORKROOM_LAUNCHD_PLIST"
else
  info "Autostart LaunchAgent already absent: $AGENTWORKROOM_LAUNCHD_PLIST"
fi
