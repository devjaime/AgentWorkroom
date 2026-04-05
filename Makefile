.PHONY: build

build:
	pnpm build

.PHONY: agentworkroom-bootstrap agentworkroom-start agentworkroom-stop agentworkroom-status agentworkroom-autostart-install agentworkroom-autostart-uninstall agentworkroom-repair-config

agentworkroom-bootstrap:
	bash scripts/agentworkroom-bootstrap-local.sh

agentworkroom-start:
	bash scripts/agentworkroom-start-local.sh

agentworkroom-stop:
	bash scripts/agentworkroom-stop-local.sh

agentworkroom-status:
	bash scripts/agentworkroom-status-local.sh

agentworkroom-autostart-install:
	bash scripts/agentworkroom-install-autostart.sh

agentworkroom-autostart-uninstall:
	bash scripts/agentworkroom-uninstall-autostart.sh

agentworkroom-repair-config:
	bash scripts/agentworkroom-repair-openclaw-config.sh
