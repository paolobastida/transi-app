# Transi — Guía de despliegue (Fase 10)

> Cómo poner el backend en un VPS propio con HTTPS, y cómo generar el APK.
> Las decisiones de despliegue están en [`adr/006-despliegue-vps.md`](adr/006-despliegue-vps.md).

El paquete de despliegue son tres piezas:

- `backend/Dockerfile` — la imagen del servidor.
- `docker-compose.prod.yml` — base + servidor + Caddy (HTTPS).
- `deploy/Caddyfile` — el reverse proxy con certificado automático.

---

## 1. Requisitos

- Un **VPS** (Ubuntu 22.04 o similar) con acceso SSH.
- Un **dominio** (ej. `transi.tudominio.com`) que puedas apuntar al VPS.
- **Docker** y **Docker Compose** instalados en el VPS.

---

## 2. Preparar el VPS

```sh
# Conectarse
ssh usuario@IP_DEL_VPS

# Actualizar el sistema
sudo apt update && sudo apt upgrade -y

# Firewall: solo SSH, HTTP y HTTPS
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# Instalar Docker (script oficial)
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker "$USER"   # cerrar y volver a entrar
```

---

## 3. Apuntar el dominio

En el panel de tu proveedor de dominio, creá un registro **A**:

```
transi.tudominio.com  →  IP_DEL_VPS
```

Esperá a que propague (unos minutos). **Caddy necesita esto** para pedir el
certificado HTTPS.

---

## 4. Bajar el código y configurar

```sh
git clone <URL-del-repositorio> transi
cd transi
cp deploy/.env.prod.example .env
nano .env          # completar DOMINIO, contraseñas y JWT_SECRET
```

> **Importante:** `.env` **no** se sube al repositorio (está en `.gitignore`).
> Usá contraseñas largas y únicas, y un `JWT_SECRET` distinto de todo lo demás.

---

## 5. Levantar todo

```sh
docker compose --env-file .env -f docker-compose.prod.yml up -d --build
```

Verificar:

```sh
curl https://transi.tudominio.com/salud
# {"estado":"ok"}
```

Caddy obtiene el certificado solo. Si falla, revisá que el dominio apunte al
VPS y que los puertos 80/443 estén abiertos.

---

## 6. Respaldos automáticos de PostgreSQL

El script `deploy/respaldar-postgres.sh` genera un `.sql` con fecha.

```sh
# Probar una vez
./deploy/respaldar-postgres.sh

# Programar uno diario a las 3:00 con cron
crontab -e
```

Agregar:

```
0 3 * * * cd /home/usuario/transi && ./deploy/respaldar-postgres.sh >> respaldos-db/cron.log 2>&1
```

> Guardá esos `.sql` **fuera** del VPS también (copia a tu computadora o a un
> almacenamiento externo): un respaldo en el mismo disco no protege de una falla
> del disco.

---

## 7. Actualizar el servidor

```sh
cd transi
git pull
docker compose --env-file .env -f docker-compose.prod.yml up -d --build
```

---

## 8. Ver y depurar

```sh
docker compose --env-file .env -f docker-compose.prod.yml ps
docker compose --env-file .env -f docker-compose.prod.yml logs -f api
docker compose --env-file .env -f docker-compose.prod.yml logs -f caddy
```

---

## 9. Checklist de responsabilidades (ADR-006)

Asumimos estas tareas al usar un VPS propio:

- [ ] SSH con clave (no contraseña) y actualizaciones del sistema.
- [ ] **HTTPS obligatorio** (Caddy) — sin HTTPS, el JWT no sirve.
- [ ] Firewall: solo 22, 80 y 443.
- [ ] PostgreSQL con contraseña fuerte y **respaldos automáticos**.
- [ ] Reinicio automático de los servicios (`restart: unless-stopped`).
- [ ] Monitoreo básico de que el sitio responde.

---

## 10. La app (APK de Android)

```sh
cd app
flutter build apk --release \
  --dart-define=API_BASE_URL=https://transi.tudominio.com
```

El APK queda en `app/build/app/outputs/flutter-apk/app-release.apk`.

> **Firma:** para publicar en la tienda hay que firmar el APK con un keystore
> propio (`android/key.properties` + `keytool`). El keystore **no** se sube al
> repositorio. Para instalar de forma directa en un dispositivo, el APK de
> release sin firmar alcanza.

---

## 11. Sobre los archivos (fotos, audios, respaldos)

Hoy los archivos se guardan en un **volumen de disco** del servidor
(`transi-archivos`). El ADR-005 eligió **Firebase Storage** como destino final,
porque el disco de un VPS no es suficientemente duradero. Migrar es cambiar solo
el adaptador `ArchivoAlmacen` (el puerto ya existe), sin tocar el resto.

---

## 12. Seguridad — recordatorio

- Nunca subir `.env` ni el keystore al repositorio.
- `JWT_SECRET` estable y secreto; rotarlo invalida los access tokens.
- Restringir `CORS_ORIGENES` al origen real de la app web en producción.
- HTTPS siempre: es lo que protege las contraseñas y los tokens en tránsito.
