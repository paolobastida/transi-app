# ADR 002 — Backend: Go

**Fecha:** 2026-10-06 · **Estado:** Aceptado

## Contexto

El servidor debe: registrar usuarios, recibir respaldos bajo demanda, servir
la API y aplicar las reglas R1–R8. En el repo ya existe un esqueleto Go
(`/salud`, Makefile, docker-compose con Postgres).

## Decisión

Escribir el servidor en **Go**, usando `net/http` de la estándar como base
HTTP (sin framework pesado). Arquitectura hexagonal: interfaces (puertos) en
`internal/`, adaptadores HTTP y de base de datos en `internal/adapters/`.

## Consecuencias

- ✅ Se aprovecha el esqueleto existente; no se tira trabajo hecho.
- ✅ Interfaces de Go encajan natural con puertos/adaptadores.
- ✅ Binario único → imagen Docker pequeña y despliegue simple (Fase E).
- ✅ Poca magia: código legible para alguien que está aprendiendo.
- ⚠️ Dos lenguajes en el proyecto (Dart en el celular, Go en el servidor).
  Es aceptado: los dos hexágonos solo se hablan por HTTP/JSON.

## Alternativas descartadas

- **Dart en servidor:** un solo lenguaje con Flutter, pero arrancaría de
  cero y se descarta el esqueleto ya funcionando.
- **Node + TypeScript / Python:** curvas adicionales sin beneficio decisivo.

## Nota HTTP

`net/http` + middleware estándar. Si se necesitan rutas con parámetros tipo
`/tratamientos/{id}` en el futuro, evaluar `go-chi/chi` en un ADR nuevo.
