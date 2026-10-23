use std::time::Duration;

use keyring_core::Entry;
use reqwest::{Method, StatusCode};
use serde::{Deserialize, Serialize};
use serde_json::json;

use crate::modelo::Usuario;

const SERVICIO: &str = "app.transi.desktop";
const CLAVE_SESION: &str = "sesion";
const CLAVE_USUARIO: &str = "usuario";

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Sesion {
    pub acceso: String,
    pub refresco: String,
}

/// Cliente de la API. Guarda los tokens en el llavero del sistema, no en disco
/// ni en el webview: el frontend nunca ve el token de refresco.
pub struct Api {
    cliente: reqwest::Client,
    base: String,
}

impl Api {
    pub fn nuevo() -> Self {
        let base =
            std::env::var("TRANSIBASE_URL").unwrap_or_else(|_| "http://localhost:8080".to_string());
        let cliente = reqwest::Client::builder()
            .timeout(Duration::from_secs(120))
            .build()
            .expect("no se pudo crear el cliente HTTP");
        Self { cliente, base }
    }

    fn url(&self, ruta: &str) -> String {
        format!("{}{}", self.base, ruta)
    }

    /// U1 · Crear cuenta.
    pub async fn registrar(&self, email: &str, clave: &str) -> Result<(), String> {
        let respuesta = self
            .cliente
            .post(self.url("/auth/registro"))
            .json(&json!({ "email": email, "clave": clave }))
            .send()
            .await
            .map_err(|_| "No pudimos conectar. Revisá tu conexión.".to_string())?;
        if respuesta.status().is_success() {
            Ok(())
        } else {
            Err(mensaje_de_error(respuesta).await)
        }
    }

    /// U2 · Iniciar sesión y traer los datos de la cuenta.
    pub async fn entrar(&self, email: &str, clave: &str) -> Result<Usuario, String> {
        let respuesta = self
            .cliente
            .post(self.url("/auth/login"))
            .json(&json!({ "email": email, "clave": clave }))
            .send()
            .await
            .map_err(|_| "No pudimos conectar. Revisá tu conexión.".to_string())?;
        if !respuesta.status().is_success() {
            return Err(mensaje_de_error(respuesta).await);
        }
        let sesion: Sesion = respuesta
            .json()
            .await
            .map_err(|_| "El servidor devolvió una sesión inválida".to_string())?;
        guardar_sesion(&sesion)?;

        let usuario = self.quien_soy().await?;
        guardar_usuario(&usuario)?;
        Ok(usuario)
    }

    async fn quien_soy(&self) -> Result<Usuario, String> {
        let texto = self
            .get_autenticado("/auth/yo")
            .await
            .map_err(|e| format!("No pudimos leer tu cuenta: {e}"))?;
        serde_json::from_str(&texto).map_err(|_| "El servidor devolvió una cuenta inválida".into())
    }

    /// U3 · Devuelve el usuario guardado, sin usar red (offline-first).
    pub fn sesion_actual(&self) -> Result<Option<Usuario>, String> {
        if leer_sesion().is_none() {
            return Ok(None);
        }
        Ok(leer_usuario())
    }

    /// Cerrar sesión: revoca el refresh (si hay red) y limpia el llavero.
    pub async fn salir(&self) -> Result<(), String> {
        if let Some(sesion) = leer_sesion() {
            let _ = self
                .cliente
                .post(self.url("/auth/logout"))
                .json(&json!({ "refresco": sesion.refresco }))
                .send()
                .await;
        }
        borrar_sesion();
        borrar_usuario();
        Ok(())
    }

    /// PUT autenticado con cuerpo de texto (lo usa el respaldo).
    pub async fn put_texto(&self, ruta: &str, cuerpo: &str) -> Result<(), String> {
        let mut sesion = leer_sesion().ok_or("No hay sesión iniciada")?;
        let mut respuesta = self.pedir(Method::PUT, ruta, Some(cuerpo), &sesion).await?;
        if respuesta.status() == StatusCode::UNAUTHORIZED {
            sesion = self.refrescar(&sesion).await?;
            respuesta = self.pedir(Method::PUT, ruta, Some(cuerpo), &sesion).await?;
        }
        if !respuesta.status().is_success() {
            return Err(format!(
                "No se pudo subir el respaldo (HTTP {})",
                respuesta.status()
            ));
        }
        Ok(())
    }

    /// GET autenticado que devuelve texto (lo usa el respaldo).
    pub async fn get_texto(&self, ruta: &str) -> Result<String, String> {
        let mut sesion = leer_sesion().ok_or("No hay sesión iniciada")?;
        let mut respuesta = self.pedir(Method::GET, ruta, None, &sesion).await?;
        if respuesta.status() == StatusCode::UNAUTHORIZED {
            sesion = self.refrescar(&sesion).await?;
            respuesta = self.pedir(Method::GET, ruta, None, &sesion).await?;
        }
        if !respuesta.status().is_success() {
            return Err(format!(
                "No se pudo bajar el respaldo (HTTP {})",
                respuesta.status()
            ));
        }
        respuesta
            .text()
            .await
            .map_err(|_| "No se pudo leer el respaldo".to_string())
    }

    async fn get_autenticado(&self, ruta: &str) -> Result<String, String> {
        let mut sesion = leer_sesion().ok_or("No hay sesión iniciada")?;
        let mut respuesta = self.pedir(Method::GET, ruta, None, &sesion).await?;
        if respuesta.status() == StatusCode::UNAUTHORIZED {
            sesion = self.refrescar(&sesion).await?;
            respuesta = self.pedir(Method::GET, ruta, None, &sesion).await?;
        }
        if !respuesta.status().is_success() {
            return Err(mensaje_de_error(respuesta).await);
        }
        respuesta
            .text()
            .await
            .map_err(|_| "No se pudo leer la respuesta".to_string())
    }

    async fn pedir(
        &self,
        metodo: Method,
        ruta: &str,
        cuerpo: Option<&str>,
        sesion: &Sesion,
    ) -> Result<reqwest::Response, String> {
        let mut peticion = self
            .cliente
            .request(metodo, self.url(ruta))
            .bearer_auth(&sesion.acceso);
        if let Some(cuerpo) = cuerpo {
            peticion = peticion
                .header("Content-Type", "application/json")
                .body(cuerpo.to_string());
        }
        peticion
            .send()
            .await
            .map_err(|_| "No pudimos conectar. Revisá tu conexión.".to_string())
    }

    async fn refrescar(&self, sesion: &Sesion) -> Result<Sesion, String> {
        let respuesta = self
            .cliente
            .post(self.url("/auth/refresh"))
            .json(&json!({ "refresco": sesion.refresco }))
            .send()
            .await
            .map_err(|_| "No pudimos conectar. Revisá tu conexión.".to_string())?;

        if matches!(
            respuesta.status(),
            StatusCode::UNAUTHORIZED | StatusCode::FORBIDDEN
        ) {
            // Solo un 401/403 significa que la sesión venció. Un 5xx no debe
            // expulsar al usuario: puede ser un pico del servidor.
            borrar_sesion();
            borrar_usuario();
            return Err("La sesión venció; volvé a entrar".into());
        }
        if !respuesta.status().is_success() {
            return Err("No pudimos renovar la sesión. Probá de nuevo en un momento.".into());
        }
        let nueva: Sesion = respuesta
            .json()
            .await
            .map_err(|_| "El servidor devolvió una sesión inválida".to_string())?;
        guardar_sesion(&nueva)?;
        Ok(nueva)
    }
}

async fn mensaje_de_error(respuesta: reqwest::Response) -> String {
    let estado = respuesta.status();
    let texto = respuesta.text().await.unwrap_or_default();
    if let Ok(json) = serde_json::from_str::<serde_json::Value>(&texto) {
        if let Some(mensaje) = json
            .get("error")
            .and_then(|e| e.get("mensaje"))
            .and_then(|m| m.as_str())
        {
            return mensaje.to_string();
        }
    }
    format!("Ocurrió un error (HTTP {estado})")
}

// ---------------------------------------------------------------------------
// Sesión en el llavero del sistema
// ---------------------------------------------------------------------------

/// Prepara el llavero del sistema con el store nativo de cada plataforma.
///
/// `keyring-core` no elige el store automáticamente (a diferencia de la feature
/// `v1` de `keyring`, que no soporta iOS ni Android en runtime). Registrarlo acá
/// hace que la misma sesión cifrada funcione en desktop y móvil.
pub fn inicializar_llavero() -> Result<(), String> {
    #[cfg(target_os = "macos")]
    {
        use apple_native_keyring_store::keychain::Store;
        keyring_core::set_default_store(Store::new().map_err(|e| e.to_string())?);
    }
    #[cfg(target_os = "ios")]
    {
        use apple_native_keyring_store::protected::Store;
        keyring_core::set_default_store(Store::new().map_err(|e| e.to_string())?);
    }
    #[cfg(target_os = "android")]
    {
        use std::collections::HashMap;

        use android_native_keyring_store::Store;

        let store = Store::new_with_configuration(&HashMap::new())
            .map_err(|e| format!("no se pudo abrir el llavero de Android: {e}"))?;
        keyring_core::set_default_store(store);
    }
    #[cfg(target_os = "windows")]
    {
        use windows_native_keyring_store::Store;
        keyring_core::set_default_store(Store::new().map_err(|e| e.to_string())?);
    }
    #[cfg(all(
        unix,
        not(any(target_os = "macos", target_os = "ios", target_os = "android"))
    ))]
    {
        use zbus_secret_service_keyring_store::Store;
        keyring_core::set_default_store(Store::new().map_err(|e| e.to_string())?);
    }
    Ok(())
}

fn entrada(clave: &str) -> Result<Entry, String> {
    Entry::new(SERVICIO, clave).map_err(|e| format!("no se pudo abrir el llavero: {e}"))
}

pub fn leer_sesion() -> Option<Sesion> {
    let secreto = entrada(CLAVE_SESION).ok()?.get_password().ok()?;
    serde_json::from_str(&secreto).ok()
}

fn guardar_sesion(sesion: &Sesion) -> Result<(), String> {
    let texto = serde_json::to_string(sesion).map_err(|e| e.to_string())?;
    entrada(CLAVE_SESION)?
        .set_password(&texto)
        .map_err(|e| format!("no se pudo guardar la sesión: {e}"))
}

fn borrar_sesion() {
    if let Ok(entrada) = entrada(CLAVE_SESION) {
        let _ = entrada.delete_credential();
    }
}

pub fn leer_usuario() -> Option<Usuario> {
    let secreto = entrada(CLAVE_USUARIO).ok()?.get_password().ok()?;
    serde_json::from_str(&secreto).ok()
}

fn guardar_usuario(usuario: &Usuario) -> Result<(), String> {
    let texto = serde_json::to_string(usuario).map_err(|e| e.to_string())?;
    entrada(CLAVE_USUARIO)?
        .set_password(&texto)
        .map_err(|e| format!("no se pudo guardar la cuenta: {e}"))
}

fn borrar_usuario() {
    if let Ok(entrada) = entrada(CLAVE_USUARIO) {
        let _ = entrada.delete_credential();
    }
}
