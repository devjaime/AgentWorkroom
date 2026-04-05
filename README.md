# AgentWorkroom

AgentWorkroom is a personal AI operating system built on top of the OpenClaw codebase.
It is designed to run as an always-on workroom for one operator, combining local and cloud models, messaging channels, home automation, dashboards, cron jobs, and multi-agent execution into a single control plane.

This repository starts from a clean upstream OpenClaw baseline and becomes the home for the custom product roadmap, migration work, and operational hardening.

## What AgentWorkroom adds

- Local-first model routing with cloud fallback
- Telegram as control channel and WhatsApp as the next recommended daily-use channel
- Home Assistant and IoT automation workflows
- Dashboard for tokens, model usage, service health, costs, CPU/RAM, and audit trails
- Persistent background work via cron jobs, Task Flow, and automation runtimes
- A migration path toward a more production-oriented agent architecture inspired by modern coding agents

## Current baseline

- Upstream foundation: OpenClaw `2026.4.2`
- Runtime focus: macOS + Ollama + OpenClaw gateway
- Local model strategy:
  - text/tools: `gemma4-openclaw`
  - image/vision: `qwen3-vl:8b`
- Cloud strategy:
  - enable only when it improves quality, context window, or tool reliability

## Repository goals

1. Turn OpenClaw into a true personal AI operating system
2. Keep the local stack stable enough for 24/7 use
3. Route work intelligently between local and cloud models
4. Add safe autonomy for GitHub, dashboards, IoT, and scheduled tasks
5. Evolve the internals toward a generic tool runtime, stronger memory, and better orchestration

## Start here

- English migration guide: `docs/reference/agentworkroom-migration.md`
- Local stack guide: `docs/reference/agentworkroom-local-stack.md`
- Spanish overview: `README.es.md`
- Architecture prompt and templates:
  - `docs/reference/templates/personal-ai-os/AGENTS.md`
  - `docs/reference/templates/personal-ai-os/INITIAL_ARCHITECT_PROMPT.es.md`
  - `docs/reference/templates/personal-ai-os/PHASE_1_EXECUTION_PLAN.es.md`

## Migration strategy

AgentWorkroom is not a blind rename of OpenClaw.
The migration strategy is:

1. keep upstream OpenClaw healthy and updateable
2. isolate custom product decisions in dedicated docs and modules
3. move toward a stronger internal architecture in phases
4. preserve compatibility while introducing local-first AI workflows and product-specific UX

## Immediate next steps

1. Reapply the custom dashboard and monitoring UX on top of this clean baseline
2. Reconcile local-only changes that lived in the previous broken checkout
3. Finish the Tool Runtime phase with explicit metadata and registry-first routing
4. Add channel expansion, beginning with WhatsApp alongside Telegram
5. Continue the local/cloud model policy and service watchdog work

## Upstream credit

AgentWorkroom is based on the excellent [OpenClaw](https://github.com/openclaw/openclaw) project.
This repository keeps that foundation while exploring a more personalized AI operations product.


## Local stack commands

Run AgentWorkroom as the control point for your local environment:

```bash
pnpm agentworkroom:bootstrap
pnpm agentworkroom:start
pnpm agentworkroom:status
pnpm agentworkroom:stop
```

This starts the OpenClaw gateway from this repository and monitors Ollama, Home Assistant, and n8n from the same entrypoint.
By default, the gateway runs inside a repo-managed tmux session so it survives terminal disconnects and remains controllable through the same scripts.
