.PHONY: build

build:
	pnpm build

.PHONY: agentworkroom-bootstrap agentworkroom-start agentworkroom-stop agentworkroom-status

agentworkroom-bootstrap:
	bash scripts/agentworkroom-bootstrap-local.sh

agentworkroom-start:
	bash scripts/agentworkroom-start-local.sh

agentworkroom-stop:
	bash scripts/agentworkroom-stop-local.sh

agentworkroom-status:
	bash scripts/agentworkroom-status-local.sh
