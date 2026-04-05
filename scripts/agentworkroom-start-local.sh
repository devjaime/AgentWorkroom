#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/agentworkroom-common.sh
source "$(cd -- "$(dirname -- "$0")" && pwd)/agentworkroom-common.sh"

require_cmd node
require_cmd curl

ensure_compose_service "$AGENTWORKROOM_MANAGE_HOME_ASSISTANT" "${AGENTWORKROOM_HOME_ASSISTANT_COMPOSE:-}" "Home Assistant"
ensure_compose_service "$AGENTWORKROOM_MANAGE_N8N" "${AGENTWORKROOM_N8N_COMPOSE:-}" "n8n"

if pid_is_running "$AGENTWORKROOM_GATEWAY_PIDFILE"; then
  info "Gateway already running with PID $(cat "$AGENTWORKROOM_GATEWAY_PIDFILE")"
  exit 0
fi

if port_is_listening "$AGENTWORKROOM_GATEWAY_PORT"; then
  warn "Port $AGENTWORKROOM_GATEWAY_PORT is already in use by another process"
  port_listener_info "$AGENTWORKROOM_GATEWAY_PORT" || true
  fail "Free the port or update AGENTWORKROOM_GATEWAY_PORT in config/local-stack.env"
fi

cmd=(node scripts/run-node.mjs gateway run --bind "$AGENTWORKROOM_GATEWAY_BIND" --port "$AGENTWORKROOM_GATEWAY_PORT")
if [ "$AGENTWORKROOM_GATEWAY_FORCE" = "1" ]; then
  cmd+=(--force)
fi

info "Starting AgentWorkroom gateway from repo"
nohup env \
  OPENCLAW_HOME="$OPENCLAW_HOME" \
  OPENCLAW_STATE_DIR="$OPENCLAW_STATE_DIR" \
  OPENCLAW_CONFIG_PATH="$OPENCLAW_CONFIG_PATH" \
  "${cmd[@]}" >"$AGENTWORKROOM_GATEWAY_LOG" 2>&1 &
echo $! > "$AGENTWORKROOM_GATEWAY_PIDFILE"
sleep 3

if pid_is_running "$AGENTWORKROOM_GATEWAY_PIDFILE"; then
  info "Gateway started on http://${AGENTWORKROOM_GATEWAY_HOST}:${AGENTWORKROOM_GATEWAY_PORT}/"
else
  warn "Gateway failed to stay up; recent log tail:"
  tail -n 80 "$AGENTWORKROOM_GATEWAY_LOG" || true
  exit 1
fi
