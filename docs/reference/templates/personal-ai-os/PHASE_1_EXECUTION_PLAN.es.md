# AgentWorkroom — Plan de ejecución Fase 1

## Objetivo de la fase

Introducir un runtime de tools más explícito y robusto sin romper la compatibilidad con el sistema actual.

## Meta técnica

- contrato unificado para tools
- metadata explícita para permisos, concurrencia y descubrimiento diferido
- registry central
- adaptación progresiva de tools legacy
- mantener compatibilidad con las rutas actuales mientras migramos

## Workstreams

### A. Runtime base

- tipos base del runtime
- clasificación de tools
- adapter para tools legacy
- helpers compartidos

### B. Tool registry

- deduplicación por nombre
- orden estable para cache y prompts
- búsqueda por tags/categorías
- exportación a formato compatible con runtime actual

### C. Metadata explícita en tools críticas

Primera ola sugerida:

- `message`
- `cron`
- `gateway`
- `nodes`
- `sessions_*`

### D. ToolSearch

- discovery de tools deferred
- salida compacta y útil para el agente
- filtros por tags, mutability y source

## Criterios de done

- tools legacy siguen funcionando
- registry gobierna catálogo y lookup
- metadata explícita prevalece sobre inferencia
- tests unitarios cubren adapter y registry
- no se rompe la selección normal de tools del agente

## Riesgos

- duplicar contratos de forma inconsistente
- cambiar orden de tools y afectar prompts/cache
- mezclar metadata inferida con metadata explícita sin prioridad clara

## Mitigaciones

- runtime nuevo detrás de adapters
- rollout conservador
- orden estable de tools
- priorizar metadata explícita del tool sobre catálogo e inferencia
