# ADR 004 — Autenticación: JWT (acceso) + refresh token revocable

**Fecha:** 2026-10-06 · **Estado:** Aceptado

## Contexto

MVP con registro/login (U1–U3), R8 (solo hash), login requiere red y el token
vive en el celular. Se pidió **JWT** (decisión explícita, por encima de la
recomendación de token opaco).

## Decisión

Esquema **híbrido** para obtener lo bueno de JWT sin sus trampas:

1. **Access token (JWT)** — vida corta (~15 min), firmado con HMAC desde un
   secreto de variable de entorno. Viaja en header `Authorization: Bearer`.
2. **Refresh token** — vida larga (p. ej. 30 días), **guardado en el
   servidor** (tabla `sessions`): es la parte revocable. Rotación: cada uso
   genera uno nuevo; el viejo se invalida.
3. Contraseña: **bcrypt/argon2** (R8), nunca en claro ni en logs.
4. HTTPS: lo provee el despliegue (Fase C-6); sin HTTPS, todo esto no vale.

## Consecuencias

- ✅ Revocación real: cerrar sesión = borrar el refresh de la tabla (el
  access muere solo en ≤15 min).
- ✅ Si el access expira mientras Tina usa la app offline, no pasa nada: los
  datos ya están en la base local; el respaldo (U16) espera al re-login.
- ⚠️ La app debe manejar `401 → refrescar → reintentar` y, si el refresh
  tampoco vale, pedir re-login. Se implementa **una sola vez** en el
  adaptador HTTP del celular.
- ⚠️ Segredo JWT en env var; rotarlo invalida todos los access (los refresh
  siguen vivos).

## Alternativas descartadas

- **Token opaco puro:** recomendado originalmente por simplicidad; se descarta
  por decisión explícita de usar JWT.
- **JWT sin refresh (solo access largo):** sin revocación posible — inaceptable
  con datos de salud.
