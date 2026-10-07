.PHONY: run test build fmt vet tidy db-up db-down

# Carga ../.env si existe (para JWT_SECRET, DATABASE_URL, etc.) sin romper si falta.
run:
	set -a; [ -f ../.env ] && . ../.env; set +a; go run ./cmd/api

db-up:
	docker compose -f ../docker-compose.yml up -d --wait

db-down:
	docker compose -f ../docker-compose.yml down

test:
	set -a; [ -f ../.env ] && . ../.env; set +a; go test ./...

build:
	go build -o bin/transi-api ./cmd/api

fmt:
	go fmt ./...

vet:
	go vet ./...

tidy:
	go mod tidy
