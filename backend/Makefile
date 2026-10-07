.PHONY: run test build fmt vet tidy db-up db-down

run:
	go run ./cmd/api

db-up:
	docker compose -f ../docker-compose.yml up -d --wait

db-down:
	docker compose -f ../docker-compose.yml down

test:
	go test ./...

build:
	go build -o bin/transi-api ./cmd/api

fmt:
	go fmt ./...

vet:
	go vet ./...

tidy:
	go mod tidy
