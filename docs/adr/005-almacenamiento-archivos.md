# ADR 005 — Almacenamiento de archivos: Firebase Storage (GCS) vía servidor

**Fecha:** 2026-10-06 · **Estado:** Aceptado

## Contexto

U12 sube fotos y notas de voz; U16 sube respaldos completos de datos de salud.
El disco del servidor no es suficientemente duradero para eso (un volumen
reemplazado = respaldos perdidos). El puerto `ArchivoAlmacen`
(`architecture.md` §2) esconde precisamente esta decisión.

## Decisión

1. **Firebase Storage** (bucket subyacente de Google Cloud Storage) como
   destino de todos los binarios: fotos, audios y archivos de respaldo.
   PostgreSQL guarda solo **metadatos y punteros**.
2. **Patrón vía servidor:** el celular sube *multipart* por la API Go
   (`POST /cambios`), el servidor persiste el archivo en el bucket y devuelve
   la referencia. **Sin SDK de Firebase en Flutter.**
3. Credenciales del bucket en variables de entorno (service account JSON);
   bucket privado — solo el servicio accede.

## Consecuencias

- ✅ Durabilidad de objetos (los respaldos no dependen del ciclo de vida del servidor).
- ✅ Un solo camino de auth: todo pasa por nuestra API con JWT (ADR 004).
- ✅ Firebase Storage es accesible desde cualquier proveedor de despliegue
  (es una API HTTPS) — no acopla el hosting.
- ⚠️ Ancho de banda doble (los bytes pasan por el servidor). Aceptable para
  fotos/audios del MVP; si pesa, se optimiza **dentro** del adaptador
  (URL firmada) sin tocar nada más — B1 de nuevo.
- ⚠️ Archivos pendientes de subir (offline) se suben en el respaldo (U16):
  primero archivos, luego la referencia (regla B5).

## Alternativas descartadas

- **Disco/volumen del servidor:** los respaldos morirían con el volumen.
- **bytea en PostgreSQL:** infla la BD y ralentiza los respaldos.
- **URL firmada directa desde Flutter:** mismo bucket, menos tránsito, pero
  agrega firmas V4 y confirmaciones ahora; posible después sin cambiar de puerto.
- **MinIO autoalojado / S3 puro:** válidos, pero se eligió Firebase Storage.
