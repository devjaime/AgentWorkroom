# AgentWorkroom

AgentWorkroom es un sistema operativo personal de IA construido sobre la base de código de OpenClaw.
La idea es convertir el gateway original en una sala de trabajo permanente para un operador: modelos locales y cloud, mensajería, automatización del hogar, dashboards, cron jobs y ejecución multiagente bajo un mismo plano de control.

## Qué agrega AgentWorkroom

- Enrutamiento local-first con fallback a modelos cloud
- Telegram como canal de control y WhatsApp como siguiente canal sugerido para uso diario
- Integración con Home Assistant e IoT
- Dashboard para tokens, costos, salud de servicios, CPU/RAM y auditoría
- Tareas persistentes por cron, Task Flow y automatizaciones
- Una hoja de ruta para evolucionar la arquitectura interna hacia un runtime de tools más robusto

## Base actual

- Base upstream: OpenClaw `2026.4.2`
- Foco de runtime: macOS + Ollama + gateway de OpenClaw
- Estrategia local:
  - texto/tools: `gemma4-openclaw`
  - imagen/visión: `qwen3-vl:8b`
- Estrategia cloud:
  - usarla solo cuando realmente mejore calidad, contexto o confiabilidad

## Documentos clave

- Guía de migración: `docs/reference/agentworkroom-migration.md`
- Guía del stack local: `docs/reference/agentworkroom-local-stack.md`
- Plantilla arquitectónica principal: `docs/reference/templates/personal-ai-os/AGENTS.md`
- Prompt inicial de arquitectura: `docs/reference/templates/personal-ai-os/INITIAL_ARCHITECT_PROMPT.es.md`
- Plan de Fase 1: `docs/reference/templates/personal-ai-os/PHASE_1_EXECUTION_PLAN.es.md`

## Estrategia de migración

1. mantener OpenClaw upstream actualizable
2. aislar decisiones de producto en módulos y docs propios
3. migrar por fases, sin reescritura ciega
4. reforzar la arquitectura para autonomía controlada, memoria, tools y observabilidad

## Próximos pasos

1. volver a montar el dashboard custom y la UX de monitoreo sobre esta base limpia
2. reconciliar cambios locales que estaban en el checkout anterior dañado
3. terminar la Fase 1 del Tool Runtime
4. expandir canales, empezando por WhatsApp junto con Telegram
5. continuar con watchdogs, política local/cloud y hardening operativo


## Comandos del stack local

Para usar AgentWorkroom como punto de entrada del entorno local:

```bash
pnpm agentworkroom:bootstrap
pnpm agentworkroom:start
pnpm agentworkroom:status
pnpm agentworkroom:stop
pnpm agentworkroom:autostart:install
pnpm agentworkroom:repair-config
pnpm agentworkroom:watchdog
```

Esto levanta el gateway de OpenClaw desde este repositorio y deja a AgentWorkroom como capa de control del stack local.
Por defecto, el gateway corre dentro de una sesión `tmux` administrada por el repo para sobrevivir cierres de terminal y seguir controlándose con los mismos scripts.
También puedes instalar un `LaunchAgent` por usuario en macOS para que, al iniciar sesión, corra un watchdog periódico del repo sin volver al arranque directo frágil del gateway por `launchd`.
Si el repo vive dentro de `Desktop`, `Documents` o `Downloads`, conviene moverlo antes a una ruta neutral para que el autoarranque headless por `launchd` no choque con las restricciones de macOS.
