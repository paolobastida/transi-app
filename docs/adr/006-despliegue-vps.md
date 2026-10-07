# ADR 006 — Despliegue: VPS propio

**Fecha:** 2026-10-06 · **Estado:** Aceptado

## Contexto

El servidor Go + PostgreSQL debe vivir en producción con HTTPS. Opciones
consideradas: Railway, Render, Cloud Run, VPS propio.

## Decisión

**VPS propio** (proveedor a definir al momento de desplegar — candidatos:
Hetzner, DigitalOcean, similar). El binario/contenedor Go y PostgreSQL corren
en el VPS.

## Consecuencias

- ✅ Control total: versión de Postgres, filesystem, red, sin dependencia de
  una plataforma.
- ✅ Costo predecible y fijo (~5 USD/mes de entrada).
- ✅ Firebase Storage (ADR 005) sigue funcionando igual: es una API HTTPS,
  no depende del host.
- ⚠️ **Responsabilidades que asumimos** (y que la Fase E debe contemplar):
  - SSH + actualizaciones del sistema
  - HTTPS (Caddy o nginx + certbot) — **obligatorio**: sin HTTPS, JWT (ADR 004) no vale
  - Firewall (solo 80/443/SSH)
  - PostgreSQL: configuración, **respaldos automáticos** de la BD
  - El VPS es un solo punto de caída: monitoreo básico y reinicio automático
    (systemd o Docker restart policy)
  - El binario se publica por SSH/CI — sin "deploy" de un clic

## Alternativas descartadas

- **Railway / Render:** cero administración, pero sin control del servidor y
  con costo por uso. Decisión elegida en contra de la recomendación: se
  prioriza control y costo fijo.
- **Cloud Run:** buen emparejamiento con Google/Firebase, más conceptos (gcloud,
  IAM, Cloud SQL).

## Pendiente para Fase E

Proveedor concreto del VPS, software de reverse proxy (Caddy vs nginx),
script de despliegue y política de respaldos de PostgreSQL.
