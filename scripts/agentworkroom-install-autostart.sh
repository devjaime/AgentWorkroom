#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/agentworkroom-common.sh
source "$(cd -- "$(dirname -- "$0")" && pwd)/agentworkroom-common.sh"

mkdir -p "$HOME/Library/LaunchAgents" "$(dirname -- "$repo_root/.agentworkroom/logs/launchagent.out.log")"

if repo_root_is_in_protected_user_dir; then
  warn "Repo path is inside a macOS protected folder: $repo_root"
  warn "LaunchAgent autostart may fail with 'Operation not permitted' until the repo is moved to a non-protected path such as \$HOME/Projects or an external SSD path."
fi

cat >"$AGENTWORKROOM_LAUNCHD_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>${AGENTWORKROOM_LAUNCHD_LABEL}</string>
    <key>ProgramArguments</key>
    <array>
      <string>/bin/bash</string>
      <string>${repo_root}/scripts/agentworkroom-watchdog.sh</string>
    </array>
    <key>WorkingDirectory</key>
    <string>${repo_root}</string>
    <key>RunAtLoad</key>
    <true/>
    <key>StartInterval</key>
    <integer>${AGENTWORKROOM_WATCHDOG_INTERVAL_SECONDS}</integer>
    <key>EnvironmentVariables</key>
    <dict>
      <key>PATH</key>
      <string>/opt/homebrew/bin:/usr/local/bin:${HOME}/Library/pnpm:/usr/bin:/bin:/usr/sbin:/sbin</string>
      <key>HOME</key>
      <string>${HOME}</string>
    </dict>
    <key>StandardOutPath</key>
    <string>${repo_root}/.agentworkroom/logs/launchagent.out.log</string>
    <key>StandardErrorPath</key>
    <string>${repo_root}/.agentworkroom/logs/launchagent.err.log</string>
  </dict>
</plist>
EOF

chmod 644 "$AGENTWORKROOM_LAUNCHD_PLIST"

launchctl bootout "$(launchctl_domain)" "$AGENTWORKROOM_LAUNCHD_PLIST" >/dev/null 2>&1 || true
launchctl enable "$(launchctl_service_target)" >/dev/null 2>&1 || true
launchctl bootstrap "$(launchctl_domain)" "$AGENTWORKROOM_LAUNCHD_PLIST"
launchctl kickstart -k "$(launchctl_service_target)" >/dev/null 2>&1 || true

info "Installed autostart LaunchAgent: $AGENTWORKROOM_LAUNCHD_PLIST"
info "The login session will now run the AgentWorkroom watchdog every ${AGENTWORKROOM_WATCHDOG_INTERVAL_SECONDS}s."
