use tauri::State;

use crate::{
    AppState, db,
    modelo::{Cambio, EntradaAdjunto, EntradaTratamiento, EventoTimeline, Tratamiento, Usuario},
};

fn error(e: impl ToString) -> String {
    e.to_string()
}

fn bloquear_base() -> String {
    "no se pudo acceder a la base local".to_string()
}

/// Reagenda los avisos después de un cambio en los tratamientos. En desktop no
/// hace nada (el hilo periódico relee la base); en móvil reprograma el sistema.
fn resincronizar(app: &tauri::AppHandle) {
    if let Err(error) = crate::recordatorios::sincronizar(app) {
        eprintln!("recordatorios: {error}");
    }
}

// ---------------------------------------------------------------------------
// Identidad
// ---------------------------------------------------------------------------

#[tauri::command]
pub async fn registrar(
    email: String,
    clave: String,
    state: State<'_, AppState>,
) -> Result<(), String> {
    state.api.registrar(&email, &clave).await
}

#[tauri::command]
pub async fn entrar(
    email: String,
    clave: String,
    app: tauri::AppHandle,
    state: State<'_, AppState>,
) -> Result<Usuario, String> {
    let usuario = state.api.entrar(&email, &clave).await?;
    resincronizar(&app);
    Ok(usuario)
}

#[tauri::command]
pub async fn sesion_actual(state: State<'_, AppState>) -> Result<Option<Usuario>, String> {
    state.api.sesion_actual()
}

#[tauri::command]
pub async fn salir(app: tauri::AppHandle, state: State<'_, AppState>) -> Result<(), String> {
    let _ = state.api.salir().await;
    {
        let mut conexion = state.db.lock().map_err(|_| bloquear_base())?;
        db::purgar(&mut conexion).map_err(error)?;
    }
    resincronizar(&app);
    Ok(())
}

// ---------------------------------------------------------------------------
// Tratamientos
// ---------------------------------------------------------------------------

#[tauri::command]
pub fn listar_tratamientos(
    usuario_id: String,
    estado: Option<String>,
    state: State<'_, AppState>,
) -> Result<Vec<Tratamiento>, String> {
    let conexion = state.db.lock().map_err(|_| bloquear_base())?;
    db::listar_tratamientos(&conexion, &usuario_id, estado.as_deref()).map_err(error)
}

#[tauri::command]
pub fn crear_tratamiento(
    usuario_id: String,
    entrada: EntradaTratamiento,
    app: tauri::AppHandle,
    state: State<'_, AppState>,
) -> Result<Tratamiento, String> {
    let creado = {
        let conexion = state.db.lock().map_err(|_| bloquear_base())?;
        db::crear_tratamiento(&conexion, &usuario_id, entrada).map_err(error)?
    };
    resincronizar(&app);
    Ok(creado)
}

#[tauri::command]
pub fn actualizar_tratamiento(
    tratamiento: Tratamiento,
    app: tauri::AppHandle,
    state: State<'_, AppState>,
) -> Result<(), String> {
    {
        let conexion = state.db.lock().map_err(|_| bloquear_base())?;
        db::actualizar_tratamiento(&conexion, &tratamiento).map_err(error)?;
    }
    resincronizar(&app);
    Ok(())
}

#[tauri::command]
pub fn desactivar_tratamiento(
    id: String,
    usuario_id: String,
    app: tauri::AppHandle,
    state: State<'_, AppState>,
) -> Result<(), String> {
    {
        let conexion = state.db.lock().map_err(|_| bloquear_base())?;
        db::desactivar_tratamiento(&conexion, &id, &usuario_id).map_err(error)?;
    }
    resincronizar(&app);
    Ok(())
}

// ---------------------------------------------------------------------------
// Cambios
// ---------------------------------------------------------------------------

#[tauri::command]
pub fn listar_cambios(
    usuario_id: String,
    state: State<'_, AppState>,
) -> Result<Vec<Cambio>, String> {
    let conexion = state.db.lock().map_err(|_| bloquear_base())?;
    db::listar_cambios(&conexion, &usuario_id).map_err(error)
}

#[tauri::command]
pub fn crear_cambio(
    usuario_id: String,
    fecha: String,
    descripcion: String,
    adjuntos: Vec<EntradaAdjunto>,
    state: State<'_, AppState>,
) -> Result<Cambio, String> {
    let mut conexion = state.db.lock().map_err(|_| bloquear_base())?;
    db::crear_cambio(&mut conexion, &usuario_id, &fecha, &descripcion, adjuntos).map_err(error)
}

#[tauri::command]
pub fn desactivar_cambio(
    id: String,
    usuario_id: String,
    state: State<'_, AppState>,
) -> Result<(), String> {
    let conexion = state.db.lock().map_err(|_| bloquear_base())?;
    db::desactivar_cambio(&conexion, &id, &usuario_id).map_err(error)
}

// ---------------------------------------------------------------------------
// Línea de tiempo
// ---------------------------------------------------------------------------

#[tauri::command]
pub fn linea_de_tiempo(
    usuario_id: String,
    desde: Option<String>,
    hasta: Option<String>,
    state: State<'_, AppState>,
) -> Result<Vec<EventoTimeline>, String> {
    let conexion = state.db.lock().map_err(|_| bloquear_base())?;
    db::linea_de_tiempo(&conexion, &usuario_id, desde.as_deref(), hasta.as_deref()).map_err(error)
}

// ---------------------------------------------------------------------------
// Respaldos
// ---------------------------------------------------------------------------

#[tauri::command]
pub fn pendientes(usuario_id: String, state: State<'_, AppState>) -> Result<i64, String> {
    let conexion = state.db.lock().map_err(|_| bloquear_base())?;
    db::pendientes(&conexion, &usuario_id).map_err(error)
}

#[tauri::command]
pub fn ultimo_respaldo(state: State<'_, AppState>) -> Result<Option<String>, String> {
    let conexion = state.db.lock().map_err(|_| bloquear_base())?;
    db::ultimo_respaldo(&conexion).map_err(error)
}

#[tauri::command]
pub async fn respaldar(usuario_id: String, state: State<'_, AppState>) -> Result<(), String> {
    let snapshot = {
        let conexion = state.db.lock().map_err(|_| bloquear_base())?;
        db::snapshot(&conexion, &usuario_id).map_err(error)?
    };
    let cuerpo = serde_json::to_string(&snapshot).map_err(error)?;
    state.api.put_texto("/respaldos", &cuerpo).await?;

    let mut conexion = state.db.lock().map_err(|_| bloquear_base())?;
    db::marcar_respaldado(&mut conexion, &usuario_id).map_err(error)
}

#[tauri::command]
pub async fn restaurar(
    usuario_id: String,
    app: tauri::AppHandle,
    state: State<'_, AppState>,
) -> Result<(), String> {
    let crudo = state.api.get_texto("/respaldos/ultimo").await?;
    let snapshot = serde_json::from_str(&crudo).map_err(error)?;

    {
        let mut conexion = state.db.lock().map_err(|_| bloquear_base())?;
        db::reemplazar_todo(&mut conexion, &usuario_id, &snapshot).map_err(error)?;
    }
    resincronizar(&app);
    Ok(())
}

// ---------------------------------------------------------------------------
// Notificaciones
// ---------------------------------------------------------------------------

#[tauri::command]
pub fn solicitar_permiso_notificaciones(app: tauri::AppHandle) -> Result<bool, String> {
    use tauri::plugin::PermissionState;
    use tauri_plugin_notification::NotificationExt;

    let notificaciones = app.notification();
    let estado = notificaciones.permission_state().map_err(error)?;
    if estado != PermissionState::Granted && estado != PermissionState::Denied {
        notificaciones.request_permission().map_err(error)?;
    }
    Ok(notificaciones.permission_state().map_err(error)? == PermissionState::Granted)
}
