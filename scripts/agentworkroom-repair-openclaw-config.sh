#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/agentworkroom-common.sh
source "$(cd -- "$(dirname -- "$0")" && pwd)/agentworkroom-common.sh"

require_cmd node

if [ ! -f "$OPENCLAW_CONFIG_PATH" ]; then
  fail "OpenClaw config not found: $OPENCLAW_CONFIG_PATH"
fi

backup_path="${OPENCLAW_CONFIG_PATH}.bak-agentworkroom-$(date +%Y%m%d-%H%M%S)"
cp "$OPENCLAW_CONFIG_PATH" "$backup_path"

OPENCLAW_CONFIG_PATH="$OPENCLAW_CONFIG_PATH" node <<'EOF'
const fs = require("fs");

const configPath = process.env.OPENCLAW_CONFIG_PATH;
const raw = fs.readFileSync(configPath, "utf8");
const config = JSON.parse(raw);
const plugins = config.plugins ?? {};

let changed = false;

if (Array.isArray(plugins.allow)) {
  const nextAllow = plugins.allow.filter((id) => id !== "minimax-portal-auth");
  if (nextAllow.length !== plugins.allow.length) {
    plugins.allow = nextAllow;
    changed = true;
  }
}

if (plugins.entries && typeof plugins.entries === "object" && "minimax-portal-auth" in plugins.entries) {
  delete plugins.entries["minimax-portal-auth"];
  changed = true;
}

config.plugins = plugins;

if (changed) {
  fs.writeFileSync(configPath, `${JSON.stringify(config, null, 2)}\n`, "utf8");
  console.log("updated");
} else {
  console.log("unchanged");
}
EOF

info "Backed up config to $backup_path"
info "Repaired stale plugin references in $OPENCLAW_CONFIG_PATH"
