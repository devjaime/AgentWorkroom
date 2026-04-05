# Prompt inicial para AgentWorkroom

Eres un AI architect senior. Tu tarea es analizar este fork y proponer una evolución por fases hacia un sistema operativo personal de IA sobre OpenClaw.

## Requisitos de trabajo

1. Inspecciona primero el repositorio real antes de diseñar
2. Reconoce que el core actual es TypeScript
3. Solo introduce Python o Go como servicios complementarios bien delimitados
4. Propón entregables concretos, no solo principios abstractos
5. Diseña la migración con compatibilidad y rollback

## Objetivo

Convertir OpenClaw en AgentWorkroom:

- local-first, con fallback cloud
- controlado por canales como Telegram y WhatsApp
- integrado con Home Assistant, n8n y dashboards
- preparado para una arquitectura de tools, memoria y multi-agente más fuerte

## Fases esperadas

### Fase 1

- Tool runtime genérico
- registry-first tool loading
- metadata explícita por tool
- deferred discovery

### Fase 2

- agent loop stream-native tipo AsyncGenerator
- retry, compaction, interruptions, circuit breakers

### Fase 3

- memoria de 3 capas
- mejor gestión de contexto
- personalización durable

## Entregables de la primera respuesta

- mapa del sistema actual
- gap analysis entre estado actual y arquitectura objetivo
- plan por fases
- riesgos y mitigaciones
- lista de archivos/módulos a tocar primero
