# AgentWorkroom migration guide

## Purpose

This document describes how AgentWorkroom is being created from the OpenClaw upstream while preserving a path to future upstream updates.

## Why a new repository

The previous local customization branch accumulated important product work, but the Git object database became unhealthy.
A clean repository is the safest path for:

- reliable commits and pushes
- predictable upstream merges
- a clean public project history
- clearer product positioning

## Baseline

- Source base: OpenClaw `2026.4.2`
- New product repository: `devjaime/AgentWorkroom`
- Product direction: personal AI operating system, local-first, operator-centric, with IoT and automation workflows

## Migration principles

1. Keep upstream compatibility whenever possible
2. Avoid large rewrites without a phased architecture plan
3. Separate product documents from upstream docs when the content is custom
4. Preserve a local-first experience without sacrificing quality
5. Use cloud models only when they materially improve the outcome

## Technical direction

### Runtime model policy

- local default for routine tasks
- local multimodal model for images, screenshots, and cameras
- cloud escalation for harder coding, longer context, or higher-quality reasoning

### Product pillars

- multi-channel assistant
- dashboard and observability
- GitHub work execution
- Home Assistant and IoT control
- cron jobs and durable automation
- stronger internal tool runtime and memory architecture

## Migration phases

### Phase 0

- create clean repository
- preserve upstream codebase health
- establish new README and product framing
- capture migration docs and architecture prompts

### Phase 1

- generic tool runtime
- explicit tool metadata
- registry-first loading and routing
- dynamic tool discovery

### Phase 2

- AsyncGenerator-based agent loop
- better streaming, retries, and compacting
- clearer runtime events and interruptions

### Phase 3

- three-layer memory system
- stronger context management
- better long-running personalization

## Notes

This repository intentionally starts from a clean upstream snapshot, so some local-only experiments from the damaged checkout may need to be replayed manually in future commits.
