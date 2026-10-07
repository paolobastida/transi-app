# ADR 001 — Plataforma móvil: Flutter

**Fecha:** 2026-10-06 · **Estado:** Aceptado

## Contexto

Transi necesita app para iOS y Android con: base local offline (SQLite),
cámara y micrófono (fotos y notas de voz), formularios y línea de tiempo.
Un solo desarrollador, aprendiendo. MVP amplio (U1–U16 + offline completo).

## Decisión

Construir la app móvil con **Flutter** (lenguaje Dart).

## Consecuencias

- ✅ Un solo código y un solo lenguaje para las dos tiendas.
- ✅ Ecosistema maduro para base local (Drift/SQLite) y UI consistente.
- ✅ La arquitectura de `architecture.md` se aplica limpio: dominio y puertos
  en Dart; adaptadores HTTP/base local en `data/`.
- ⚠️ Dart es un lenguaje más para aprender (aunque su sintaxis se parece a
  Go/Java). El dominio del celular **no** se comparte con el servidor: son dos
  hexágonos separados por HTTP.

## Alternativas descartadas

- **React Native:** buena, pero exige curva JS/Node adicional; sin ventaja
  decisiva para este MVP.
- **Nativo (Swift + Kotlin):** doble código y doble curva; costo prohibivo
  para una persona sola.
