#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/agentworkroom-common.sh
source "$(cd -- "$(dirname -- "$0")" && pwd)/agentworkroom-common.sh"

gateway_url="http://${AGENTWORKROOM_GATEWAY_HOST}:${AGENTWORKROOM_GATEWAY_PORT}/"
http_code=$(http_status_code "$gateway_url")
last_state=$(get_watchdog_state)

if [ "$http_code" != "000" ]; then
  if [ "$last_state" != "healthy" ]; then
    record_watchdog_event "info" "healthy" "gateway reachable status=$http_code"
  fi
  set_watchdog_state "healthy"
  exit 0
fi

record_watchdog_event "warn" "restart-start" "gateway down; invoking start-local"
set_watchdog_state "recovering"

if /bin/bash "$repo_root/scripts/agentworkroom-start-local.sh" >> "$repo_root/$AGENTWORKROOM_WATCHDOG_LOG" 2>&1; then
  http_code=$(http_status_code "$gateway_url")
  if [ "$http_code" != "000" ]; then
    record_watchdog_event "info" "restart-ok" "gateway recovered status=$http_code"
    set_watchdog_state "healthy"
    exit 0
  fi
fi

record_watchdog_event "error" "restart-failed" "gateway still down after watchdog recovery"
set_watchdog_state "failed"
exit 1
