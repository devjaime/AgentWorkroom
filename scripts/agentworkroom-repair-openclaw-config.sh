#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/agentworkroom-common.sh
source "$(cd -- "$(dirname -- "$0")" && pwd)/agentworkroom-common.sh"

require_cmd node

if [ ! -f "$OPENCLAW_CONFIG_PATH" ]; then
  fail "OpenClaw config not found: $OPENCLAW_CONFIG_PATH"
fi

repair_output=$(
OPENCLAW_CONFIG_PATH="$OPENCLAW_CONFIG_PATH" \
AGENTWORKROOM_REPO_ROOT="$repo_root" \
node <<'EOF'
const fs = require("fs");
const path = require("path");

const configPath = process.env.OPENCLAW_CONFIG_PATH;
const repoRoot = process.env.AGENTWORKROOM_REPO_ROOT;
const raw = fs.readFileSync(configPath, "utf8");
const config = JSON.parse(raw);
const plugins = config.plugins ?? {};
const gateway = config.gateway ?? {};
const controlUi = gateway.controlUi ?? {};

let changed = false;
const changes = [];

if (Array.isArray(plugins.allow)) {
  const nextAllow = plugins.allow.filter((id) => id !== "minimax-portal-auth");
  if (nextAllow.length !== plugins.allow.length) {
    plugins.allow = nextAllow;
    changed = true;
    changes.push("removed plugins.allow minimax-portal-auth");
  }
}

if (plugins.entries && typeof plugins.entries === "object" && "minimax-portal-auth" in plugins.entries) {
  delete plugins.entries["minimax-portal-auth"];
  changed = true;
  changes.push("removed plugins.entries.minimax-portal-auth");
}

const preferredControlUiRoot = path.resolve(repoRoot, "dist", "control-ui");
const preferredControlUiIndex = path.join(preferredControlUiRoot, "index.html");
const configuredControlUiRoot =
  typeof controlUi.root === "string" && controlUi.root.trim() ? path.resolve(controlUi.root) : null;
const configuredControlUiIndex = configuredControlUiRoot
  ? path.join(configuredControlUiRoot, "index.html")
  : null;
const preferredControlUiReady = fs.existsSync(preferredControlUiIndex);
const configuredControlUiReady = configuredControlUiIndex ? fs.existsSync(configuredControlUiIndex) : false;
const protectedRoots = [
  path.resolve(process.env.HOME || "", "Desktop"),
  path.resolve(process.env.HOME || "", "Documents"),
  path.resolve(process.env.HOME || "", "Downloads"),
];
const configuredInProtectedDir = configuredControlUiRoot
  ? protectedRoots.some(
      (dir) => configuredControlUiRoot === dir || configuredControlUiRoot.startsWith(`${dir}${path.sep}`),
    )
  : false;
const configuredLooksLikeAnotherCheckout =
  configuredControlUiRoot !== null &&
  configuredControlUiRoot !== preferredControlUiRoot &&
  path.basename(configuredControlUiRoot) === "control-ui" &&
  path.basename(path.dirname(configuredControlUiRoot)) === "dist";

if (
  preferredControlUiReady &&
  configuredControlUiRoot &&
  configuredControlUiRoot !== preferredControlUiRoot &&
  (configuredInProtectedDir || !configuredControlUiReady || configuredLooksLikeAnotherCheckout)
) {
  controlUi.root = preferredControlUiRoot;
  gateway.controlUi = controlUi;
  config.gateway = gateway;
  changed = true;
  changes.push(`rewired gateway.controlUi.root to ${preferredControlUiRoot}`);
}

config.plugins = plugins;

if (changed) {
  console.log(
    JSON.stringify({
      changed: true,
      changes,
      config: `${JSON.stringify(config, null, 2)}\n`,
    }),
  );
} else {
  console.log(JSON.stringify({ changed: false, changes: [] }));
}
EOF
)

changed=$(printf '%s' "$repair_output" | node -e 'const fs=require("fs");const data=JSON.parse(fs.readFileSync(0,"utf8"));process.stdout.write(data.changed ? "1" : "0");')

if [ "$changed" = "1" ]; then
  backup_path="${OPENCLAW_CONFIG_PATH}.bak-agentworkroom-$(date +%Y%m%d-%H%M%S)"
  cp "$OPENCLAW_CONFIG_PATH" "$backup_path"
  printf '%s' "$repair_output" | node -e 'const fs=require("fs");const data=JSON.parse(fs.readFileSync(0,"utf8"));fs.writeFileSync(process.argv[1], data.config, "utf8");' "$OPENCLAW_CONFIG_PATH"
  change_summary=$(printf '%s' "$repair_output" | node -e 'const fs=require("fs");const data=JSON.parse(fs.readFileSync(0,"utf8"));process.stdout.write(data.changes.join("; "));')
  info "Backed up config to $backup_path"
  info "Updated $OPENCLAW_CONFIG_PATH"
  if [ -n "$change_summary" ]; then
    info "Applied changes: $change_summary"
  fi
else
  info "OpenClaw config already aligned: $OPENCLAW_CONFIG_PATH"
fi
