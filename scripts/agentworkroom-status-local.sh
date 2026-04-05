#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/agentworkroom-common.sh
source "$(cd -- "$(dirname -- "$0")" && pwd)/agentworkroom-common.sh"

printf 'AgentWorkroom local stack\n'
printf 'Repo: %s\n' "$repo_root"
printf 'OpenClaw home: %s\n' "$OPENCLAW_HOME"
printf 'Gateway target: http://%s:%s/\n' "$AGENTWORKROOM_GATEWAY_HOST" "$AGENTWORKROOM_GATEWAY_PORT"
printf 'Gateway runtime: %s\n' "$AGENTWORKROOM_GATEWAY_RUNTIME"
if [ -f "$AGENTWORKROOM_LAUNCHD_PLIST" ]; then
  printf 'Autostart plist: installed (%s)\n' "$AGENTWORKROOM_LAUNCHD_PLIST"
else
  printf 'Autostart plist: not installed (%s)\n' "$AGENTWORKROOM_LAUNCHD_PLIST"
fi
printf '\n'

if [ "$AGENTWORKROOM_GATEWAY_RUNTIME" = "tmux" ] && command -v tmux >/dev/null 2>&1; then
  if tmux_session_exists "$AGENTWORKROOM_TMUX_SESSION"; then
    printf 'tmux session: running (%s)\n' "$AGENTWORKROOM_TMUX_SESSION"
  else
    printf 'tmux session: stopped (%s)\n' "$AGENTWORKROOM_TMUX_SESSION"
  fi
elif launchagent_is_loaded; then
  printf 'LaunchAgent state: loaded (%s)\n' "$AGENTWORKROOM_LAUNCHD_LABEL"
else
  printf 'LaunchAgent state: not loaded (%s)\n' "$AGENTWORKROOM_LAUNCHD_LABEL"
fi

if pid_is_running "$AGENTWORKROOM_GATEWAY_PIDFILE"; then
  printf 'Gateway process: running (pid=%s)\n' "$(cat "$AGENTWORKROOM_GATEWAY_PIDFILE")"
else
  printf 'Gateway process: stopped\n'
fi

if port_is_listening "$AGENTWORKROOM_GATEWAY_PORT"; then
  printf 'Gateway listener: present on port %s\n' "$AGENTWORKROOM_GATEWAY_PORT"
  port_listener_info "$AGENTWORKROOM_GATEWAY_PORT" || true
else
  printf 'Gateway listener: none on port %s\n' "$AGENTWORKROOM_GATEWAY_PORT"
fi

gateway_http_code=$(http_status_code "http://${AGENTWORKROOM_GATEWAY_HOST}:${AGENTWORKROOM_GATEWAY_PORT}/")
if [ "$gateway_http_code" != "000" ]; then
  printf 'Gateway HTTP: reachable (status=%s)\n' "$gateway_http_code"
else
  printf 'Gateway HTTP: down\n'
fi

if http_ok "$AGENTWORKROOM_OLLAMA_URL/api/tags"; then
  printf 'Ollama: ok (%s)\n' "$AGENTWORKROOM_OLLAMA_URL"
  if curl -fsS "$AGENTWORKROOM_OLLAMA_URL/api/show" -d "{\"name\":\"$AGENTWORKROOM_REQUIRED_TEXT_MODEL\"}" >/dev/null 2>&1; then
    printf 'Text model: present (%s)\n' "$AGENTWORKROOM_REQUIRED_TEXT_MODEL"
  else
    printf 'Text model: missing (%s)\n' "$AGENTWORKROOM_REQUIRED_TEXT_MODEL"
  fi
  if curl -fsS "$AGENTWORKROOM_OLLAMA_URL/api/show" -d "{\"name\":\"$AGENTWORKROOM_REQUIRED_IMAGE_MODEL\"}" >/dev/null 2>&1; then
    printf 'Image model: present (%s)\n' "$AGENTWORKROOM_REQUIRED_IMAGE_MODEL"
  else
    printf 'Image model: missing (%s)\n' "$AGENTWORKROOM_REQUIRED_IMAGE_MODEL"
  fi
else
  printf 'Ollama: down (%s)\n' "$AGENTWORKROOM_OLLAMA_URL"
fi

if [ -n "$AGENTWORKROOM_HOME_ASSISTANT_URL" ]; then
  if http_ok "$AGENTWORKROOM_HOME_ASSISTANT_URL"; then
    printf 'Home Assistant: ok (%s)\n' "$AGENTWORKROOM_HOME_ASSISTANT_URL"
  else
    printf 'Home Assistant: down (%s)\n' "$AGENTWORKROOM_HOME_ASSISTANT_URL"
  fi
fi

if [ -n "${AGENTWORKROOM_HOME_ASSISTANT_CONTAINER:-}" ] && command -v docker >/dev/null 2>&1; then
  if container_exists "$AGENTWORKROOM_HOME_ASSISTANT_CONTAINER"; then
    if container_is_running "$AGENTWORKROOM_HOME_ASSISTANT_CONTAINER"; then
      printf 'Home Assistant container: running (%s)\n' "$AGENTWORKROOM_HOME_ASSISTANT_CONTAINER"
    else
      printf 'Home Assistant container: stopped (%s)\n' "$AGENTWORKROOM_HOME_ASSISTANT_CONTAINER"
    fi
  else
    printf 'Home Assistant container: missing (%s)\n' "$AGENTWORKROOM_HOME_ASSISTANT_CONTAINER"
  fi
fi

if [ -n "$AGENTWORKROOM_N8N_URL" ]; then
  if http_ok "$AGENTWORKROOM_N8N_URL"; then
    printf 'n8n: ok (%s)\n' "$AGENTWORKROOM_N8N_URL"
  else
    printf 'n8n: down (%s)\n' "$AGENTWORKROOM_N8N_URL"
  fi
fi

if [ -n "${AGENTWORKROOM_N8N_CONTAINER:-}" ] && command -v docker >/dev/null 2>&1; then
  if container_exists "$AGENTWORKROOM_N8N_CONTAINER"; then
    if container_is_running "$AGENTWORKROOM_N8N_CONTAINER"; then
      printf 'n8n container: running (%s)\n' "$AGENTWORKROOM_N8N_CONTAINER"
    else
      printf 'n8n container: stopped (%s)\n' "$AGENTWORKROOM_N8N_CONTAINER"
    fi
  else
    printf 'n8n container: missing (%s)\n' "$AGENTWORKROOM_N8N_CONTAINER"
  fi
fi

if [ -f "$AGENTWORKROOM_GATEWAY_LOG" ]; then
  printf '\nRecent gateway log:\n'
  tail -n 20 "$AGENTWORKROOM_GATEWAY_LOG" || true
fi
