#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/agentworkroom-common.sh
source "$(cd -- "$(dirname -- "$0")" && pwd)/agentworkroom-common.sh"

require_cmd node
require_cmd pnpm
require_cmd curl

if [ ! -f "$repo_root/config/local-stack.env" ]; then
  cp "$repo_root/config/local-stack.env.example" "$repo_root/config/local-stack.env"
  info "Created config/local-stack.env from example"
fi

if [ ! -d "$repo_root/node_modules" ]; then
  info "Installing dependencies"
  pnpm install
else
  info "Dependencies already present"
fi

if [ "$AGENTWORKROOM_BOOTSTRAP_UI_BUILD" = "1" ]; then
  info "Building Control UI"
  pnpm ui:build
fi

if [ "$AGENTWORKROOM_BOOTSTRAP_BUILD" = "1" ]; then
  if has_a2ui_bundle_or_sources; then
    info "Building runtime"
    pnpm build
  else
    warn "Skipping full runtime build because A2UI sources/bundle are not present in this checkout"
    info "Building minimal runtime artifacts for gateway startup"
    node scripts/tsdown-build.mjs --no-clean
    node scripts/runtime-postbuild.mjs
    node scripts/build-stamp.mjs
  fi
fi

if [ -f "$OPENCLAW_CONFIG_PATH" ]; then
  info "Running doctor --fix against existing OpenClaw config"
  node scripts/run-node.mjs doctor --fix || warn "doctor --fix returned non-zero; review output before production use"
else
  warn "OpenClaw config not found at $OPENCLAW_CONFIG_PATH"
  warn "Run onboarding later with: node scripts/run-node.mjs onboard --install-daemon"
fi

if http_ok "$AGENTWORKROOM_OLLAMA_URL/api/tags"; then
  info "Ollama reachable at $AGENTWORKROOM_OLLAMA_URL"
else
  warn "Ollama is not reachable at $AGENTWORKROOM_OLLAMA_URL"
fi

info "Bootstrap complete"
info "Next: scripts/agentworkroom-start-local.sh"
