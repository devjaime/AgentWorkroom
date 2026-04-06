---
summary: "Run AgentWorkroom as the local control plane for OpenClaw, Ollama, Home Assistant, and n8n"
title: "AgentWorkroom Local Stack"
---

# AgentWorkroom Local Stack

This repository can be the control point for your local stack.
That means AgentWorkroom owns the bootstrap scripts, gateway start/stop flow, and health checks, even when some services still keep their own runtime state outside the repo.

## What the repo controls

- OpenClaw source runtime from this checkout
- Gateway process lifecycle
- Control UI build
- Health checks for Ollama, Home Assistant, and n8n
- Repo-managed tmux runtime for the gateway
- Optional Docker Compose or direct container start/stop for Home Assistant and n8n

## What still lives outside the repo

- `~/.openclaw/` config, sessions, credentials, pairings, and state
- Ollama model storage and daemon lifecycle
- Existing Home Assistant instance data
- Existing n8n instance data
- secrets and API keys

This is intentional. The repo becomes the control plane without forcing fragile secrets or machine-specific state into Git.

## Files added for the local stack

- `config/local-stack.env.example`
- `scripts/agentworkroom-bootstrap-local.sh`
- `scripts/agentworkroom-start-local.sh`
- `scripts/agentworkroom-stop-local.sh`
- `scripts/agentworkroom-status-local.sh`
- `scripts/agentworkroom-install-autostart.sh`
- `scripts/agentworkroom-uninstall-autostart.sh`
- `scripts/agentworkroom-repair-openclaw-config.sh`
- `scripts/agentworkroom-watchdog.sh`

## Quick start

1. Copy the example file:

```bash
cp config/local-stack.env.example config/local-stack.env
```

2. Adjust values for your machine:

- OpenClaw home paths
- gateway port
- gateway runtime (`tmux` by default)
- Ollama URL
- Home Assistant URL
- n8n URL
- optional Docker Compose files or container names if AgentWorkroom should manage those services

3. Bootstrap the repo:

```bash
pnpm agentworkroom:bootstrap
```

4. Start the stack from the repo:

```bash
pnpm agentworkroom:start
```

5. Inspect status:

```bash
pnpm agentworkroom:status
```

6. Stop the stack:

```bash
pnpm agentworkroom:stop
```

## Autostart at login

If you want the repo to restore the stack automatically when you log in on macOS:

```bash
pnpm agentworkroom:autostart:install
```

That installs a simple per-user LaunchAgent that calls the repo-owned start script. The LaunchAgent does not run the gateway directly; it only triggers the stable tmux-based flow that this repo already manages.
The LaunchAgent now runs a lightweight watchdog on a fixed interval. If the gateway is healthy, it exits fast. If the gateway is down, it calls the repo-owned start flow and records the recovery attempt.

Important on macOS: if the repository itself lives inside a protected user folder such as `Desktop`, `Documents`, or `Downloads`, the background LaunchAgent can fail with `Operation not permitted`.
If you want true headless autostart, keep the repo in a neutral path such as `~/Projects/AgentWorkroom` or an external SSD mount, then reinstall autostart from there.

To remove it later:

```bash
pnpm agentworkroom:autostart:uninstall
```

## Repair stale OpenClaw config

If older plugin ids or renamed providers are still generating warnings during startup, run:

```bash
pnpm agentworkroom:repair-config
```

This creates a timestamped backup of `~/.openclaw/openclaw.json` first, then removes known stale references that break or pollute the local runtime.

## Watchdog and recovery visibility

The local stack now keeps lightweight recovery state under `.agentworkroom/state/`:

- `watchdog-events.log` records the last recovery actions
- `watchdog-state` keeps the last known health state

You can also run the watchdog manually:

```bash
pnpm agentworkroom:watchdog
```

And `pnpm agentworkroom:status` now shows:

- watchdog interval
- gateway uptime
- recent watchdog events
- recent watchdog recovery log

## Recommended model defaults

For the current machine profile:

- text/tools: `gemma4-openclaw:latest`
- image/vision: `qwen3-vl:8b`

The status script checks both against Ollama using `/api/show`.

## Optional service ownership

If Home Assistant or n8n are already running elsewhere, leave management disabled and AgentWorkroom will only monitor them.

If you want AgentWorkroom to start and stop them, set:

```bash
AGENTWORKROOM_MANAGE_HOME_ASSISTANT="1"
AGENTWORKROOM_HOME_ASSISTANT_COMPOSE="/absolute/path/to/homeassistant/docker-compose.yml"
AGENTWORKROOM_MANAGE_N8N="1"
AGENTWORKROOM_N8N_COMPOSE="/absolute/path/to/n8n/docker-compose.yml"
```

Then `agentworkroom:start` and `agentworkroom:stop` will call `docker compose` for those services.

If those services already exist as named containers, you can manage them directly instead:

```bash
AGENTWORKROOM_MANAGE_HOME_ASSISTANT="1"
AGENTWORKROOM_HOME_ASSISTANT_CONTAINER="homeassistant"
AGENTWORKROOM_MANAGE_N8N="1"
AGENTWORKROOM_N8N_CONTAINER="n8n"
```

## Gateway runtime

The gateway defaults to `tmux`:

```bash
AGENTWORKROOM_GATEWAY_RUNTIME="tmux"
AGENTWORKROOM_TMUX_SESSION="agentworkroom-gateway"
```

That keeps the gateway alive even if the launching terminal disconnects, while still letting the repo own the start/stop/status flow.

## Important note

This setup makes the repository the operator entrypoint, but it does not magically make Home Assistant, n8n, Ollama, or secrets repo-native.
That is a good thing: state stays where it belongs, while AgentWorkroom becomes the repeatable control layer.
