-- 001_users: cuentas de Transi (contexto Identidad).
-- R8: la contraseña se guarda solo como hash irreversible.
CREATE TABLE users (
    id            UUID PRIMARY KEY,
    email         TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
