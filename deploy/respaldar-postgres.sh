#!/usr/bin/env sh
# Respalda la base PostgreSQL de producción a un archivo .sql con fecha.
# Uso:  ./deploy/respaldar-postgres.sh
set -eu

cd "$(dirname "$0")/.."

# Cargar variables desde .env si existe.
set -a
[ -f .env ] && . ./.env
set +a

: "${POSTGRES_USER:?definí POSTGRES_USER en .env}"
: "${POSTGRES_DB:?definí POSTGRES_DB en .env}"

mkdir -p respaldos-db
archivo="respaldos-db/transi-$(date +%Y-%m-%d_%H%M).sql"

docker compose --env-file .env -f docker-compose.prod.yml exec -T db \
	pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" > "$archivo"

echo "Respaldo creado: $archivo"
