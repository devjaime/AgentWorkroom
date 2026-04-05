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
- Optional Docker Compose start/stop for Home Assistant and n8n

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

## Quick start

1. Copy the example file:

```bash
cp config/local-stack.env.example config/local-stack.env
```

2. Adjust values for your machine:

- OpenClaw home paths
- gateway port
- Ollama URL
- Home Assistant URL
- n8n URL
- optional Docker Compose files if AgentWorkroom should manage those services

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

## Important note

This setup makes the repository the operator entrypoint, but it does not magically make Home Assistant, n8n, Ollama, or secrets repo-native.
That is a good thing: state stays where it belongs, while AgentWorkroom becomes the repeatable control layer.
