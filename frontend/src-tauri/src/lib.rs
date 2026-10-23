mod api;
mod comandos;
mod db;
mod modelo;
mod recordatorios;

use tauri::Manager;

/// Estado compartido por todos los comandos.
///
/// La base local es la fuente de verdad (offline-first); el cliente de API solo
/// se usa para identidad y respaldos.
pub struct AppState {
    pub db: std::sync::Mutex<rusqlite::Connection>,
    pub api: api::Api,
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_notification::init())
        .setup(|app| {
            let directorio = app.path().app_data_dir()?;
            std::fs::create_dir_all(&directorio)?;

            let conexion = db::abrir(&directorio.join("transi.sqlite3"))?;
            api::inicializar_llavero().map_err(std::io::Error::other)?;
            app.manage(AppState {
                db: std::sync::Mutex::new(conexion),
                api: api::Api::nuevo(),
            });

            recordatorios::iniciar(app.handle().clone());
            // En móvil deja agendados los avisos que ya existían; en desktop
            // es un no-op.
            let _ = recordatorios::sincronizar(app.handle());
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            comandos::registrar,
            comandos::entrar,
            comandos::sesion_actual,
            comandos::salir,
            comandos::listar_tratamientos,
            comandos::crear_tratamiento,
            comandos::actualizar_tratamiento,
            comandos::desactivar_tratamiento,
            comandos::listar_cambios,
            comandos::crear_cambio,
            comandos::desactivar_cambio,
            comandos::linea_de_tiempo,
            comandos::pendientes,
            comandos::ultimo_respaldo,
            comandos::respaldar,
            comandos::restaurar,
            comandos::solicitar_permiso_notificaciones,
        ])
        .run(tauri::generate_context!())
        .expect("error al arrancar Transi");
}
