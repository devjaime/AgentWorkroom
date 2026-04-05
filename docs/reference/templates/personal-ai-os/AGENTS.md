# AgentWorkroom — Personal AI OS

## Project context

AgentWorkroom extends OpenClaw into a personal AI operating system.
Current stack direction: TypeScript core plus complementary Python/Go services where they make sense, with Ollama, Home Assistant, Telegram, n8n, dashboards, cron jobs, and multi-model routing.

## Architectural north star

We are evolving toward a production-oriented coding-agent architecture inspired by modern agent systems:

- agent loop with stream-native execution
- generic Tool runtime with explicit schemas, permissions, and concurrency metadata
- layered memory to fight context entropy
- stronger permission and approval flows
- progressive disclosure for skills and tools
- orchestrator-worker multi-agent patterns
- deterministic hooks and audit trails
- compaction-aware context management

## Working rules

- prefer phased migration over rewrite
- preserve upstream compatibility whenever practical
- keep the TypeScript core healthy first
- add Python/Go only for clearly bounded services
- every new tool must be typed, permission-aware, and testable
- every phase needs rollback and compatibility notes

## Language conventions

### TypeScript

- strict typing
- no unbounded `any`
- small modules and clear contracts
- colocated tests for new runtime behavior

### Python

- type hints
- docstrings
- async where appropriate
- use for bounded services, not for replacing the core blindly

### Go

- explicit error handling
- no panic-driven control flow
- use standard layout and production-minded boundaries

## Delivery expectations

- conventional commits: `feat`, `fix`, `refactor`, `docs`
- migration docs updated with architectural changes
- tests for every new runtime/tool behavior
- avoid hidden global state when adding orchestration features
