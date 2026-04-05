#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/agentworkroom-common.sh
source "$(cd -- "$(dirname -- "$0")" && pwd)/agentworkroom-common.sh"

require_cmd node
require_cmd curl

ensure_compose_service "$AGENTWORKROOM_MANAGE_HOME_ASSISTANT" "${AGENTWORKROOM_HOME_ASSISTANT_COMPOSE:-}" "Home Assistant"
ensure_compose_service "$AGENTWORKROOM_MANAGE_N8N" "${AGENTWORKROOM_N8N_COMPOSE:-}" "n8n"
ensure_container_service "$AGENTWORKROOM_MANAGE_HOME_ASSISTANT" "${AGENTWORKROOM_HOME_ASSISTANT_CONTAINER:-}" "Home Assistant"
ensure_container_service "$AGENTWORKROOM_MANAGE_N8N" "${AGENTWORKROOM_N8N_CONTAINER:-}" "n8n"

info "Refreshing minimal runtime build"
node scripts/tsdown-build.mjs --no-clean
node scripts/runtime-postbuild.mjs
node scripts/build-stamp.mjs

if port_is_listening "$AGENTWORKROOM_GATEWAY_PORT" && ! tmux_session_exists "$AGENTWORKROOM_TMUX_SESSION"; then
  warn "Port $AGENTWORKROOM_GATEWAY_PORT is already in use by another process"
  port_listener_info "$AGENTWORKROOM_GATEWAY_PORT" || true
  fail "Free the port or update AGENTWORKROOM_GATEWAY_PORT in config/local-stack.env"
fi

chmod +x "$repo_root/scripts/agentworkroom-gateway-launch.sh"
launchctl bootout "$(launchctl_domain)" "$AGENTWORKROOM_LAUNCHD_PLIST" >/dev/null 2>&1 || true
launchctl disable "$(launchctl_service_target)" >/dev/null 2>&1 || true

if [ "$AGENTWORKROOM_GATEWAY_RUNTIME" = "tmux" ]; then
  require_cmd tmux
  if tmux_session_exists "$AGENTWORKROOM_TMUX_SESSION"; then
    info "Gateway tmux session already running ($AGENTWORKROOM_TMUX_SESSION)"
  else
    info "Starting AgentWorkroom gateway from repo via tmux"
    tmux new-session -d -s "$AGENTWORKROOM_TMUX_SESSION" \
      "cd '$repo_root' && exec /bin/bash '$repo_root/scripts/agentworkroom-gateway-launch.sh' >> '$repo_root/$AGENTWORKROOM_GATEWAY_LOG' 2>&1"
  fi
else
  fail "Unsupported AGENTWORKROOM_GATEWAY_RUNTIME=$AGENTWORKROOM_GATEWAY_RUNTIME"
fi

sleep 6

if pid_is_running "$AGENTWORKROOM_GATEWAY_PIDFILE" || port_is_listening "$AGENTWORKROOM_GATEWAY_PORT"; then
  info "Gateway started on http://${AGENTWORKROOM_GATEWAY_HOST}:${AGENTWORKROOM_GATEWAY_PORT}/"
else
  warn "Gateway failed to stay up; recent log tail:"
  tail -n 80 "$AGENTWORKROOM_GATEWAY_LOG" || true
  exit 1
fi
