# Imagen del backend de Transi (multi-etapa).
# Etapa 1: compilar el binario.
FROM golang:1.27-alpine AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/transi-api ./cmd/api

# Etapa 2: imagen final mínima.
FROM alpine:3.20
RUN apk add --no-cache ca-certificates && adduser -D -u 10001 transi
WORKDIR /app
COPY --from=build /out/transi-api /app/transi-api
# Los archivos subidos viven en un volumen montado acá.
RUN mkdir -p /app/datos/archivos && chown -R transi:transi /app/datos
USER transi
EXPOSE 8080
ENTRYPOINT ["/app/transi-api"]
