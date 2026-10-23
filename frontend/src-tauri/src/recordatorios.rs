#[cfg(desktop)]
use std::collections::HashSet;
#[cfg(desktop)]
use std::time::Duration;

#[cfg(desktop)]
use chrono::Timelike;
use tauri::{AppHandle, Manager};
use tauri_plugin_notification::NotificationExt;

use crate::{AppState, db, modelo::Tratamiento};

/// Arranca el mecanismo de avisos.
///
/// - **Desktop:** Tauri ignora la programación nativa, así que corre un hilo que
///   revisa la base cada 30 s mientras la app está abierta.
/// - **Móvil:** no hay hilo; `sincronizar` agenda notificaciones nativas
///   repetidas en el sistema operativo.
#[cfg(desktop)]
pub fn iniciar(app: AppHandle) {
    std::thread::spawn(move || {
        let mut enviados: HashSet<String> = HashSet::new();
        loop {
            if let Err(error) = revisar(&app, &mut enviados) {
                eprintln!("recordatorios: {error}");
            }
            std::thread::sleep(Duration::from_secs(30));
        }
    });
}

#[cfg(mobile)]
pub fn iniciar(_app: AppHandle) {}

#[cfg(desktop)]
fn revisar(app: &AppHandle, enviados: &mut HashSet<String>) -> Result<(), String> {
    let ahora = chrono::Local::now();
    let fecha = ahora.format("%Y-%m-%d").to_string();
    let minutos = ahora.hour() as i64 * 60 + ahora.minute() as i64;

    // Las claves viejas (de otros días) no sirven y harían crecer el set.
    enviados.retain(|clave| clave.starts_with(&fecha));

    for tratamiento in activos_con_recordatorio(app)? {
        if !tratamiento.recordatorio_minutos.contains(&minutos) {
            continue;
        }
        let clave = format!("{fecha}:{minutos}:{}", tratamiento.id);
        if !enviados.insert(clave) {
            continue;
        }
        let _ = app
            .notification()
            .builder()
            .title("Es hora de tu medicación")
            .body(format!("{} · {}", tratamiento.nombre, tratamiento.dosis))
            .show();
    }

    Ok(())
}

/// Reagenda todos los recordatorios. Se llama después de crear, editar,
/// desactivar o restaurar tratamientos, y al arrancar la app.
///
/// En desktop es un no-op: el hilo de `iniciar` ya relee la base sola.
#[cfg(desktop)]
pub fn sincronizar(_app: &AppHandle) -> Result<(), String> {
    Ok(())
}

#[cfg(mobile)]
pub fn sincronizar(app: &AppHandle) -> Result<(), String> {
    use tauri_plugin_notification::{Schedule, ScheduleInterval};

    let notificaciones = app.notification();
    // Se reagenda todo: es barato y evita duplicados/huérfanos.
    notificaciones.cancel_all().map_err(|e| e.to_string())?;

    for tratamiento in activos_con_recordatorio(app)? {
        for (indice, minutos) in tratamiento.recordatorio_minutos.iter().enumerate() {
            let schedule = Schedule::Interval {
                // Solo hora y minuto: se repite todos los días a esa hora.
                interval: ScheduleInterval {
                    hour: Some((minutos / 60) as u8),
                    minute: Some((minutos % 60) as u8),
                    ..Default::default()
                },
                allow_while_idle: true,
            };
            notificaciones
                .builder()
                .id(id_notificacion(&tratamiento.id, indice))
                .title("Es hora de tu medicación")
                .body(format!("{} · {}", tratamiento.nombre, tratamiento.dosis))
                .schedule(schedule)
                .show()
                .map_err(|e| e.to_string())?;
        }
    }

    Ok(())
}

#[cfg(mobile)]
fn id_notificacion(tratamiento_id: &str, indice: usize) -> i32 {
    // FNV-1a estable: el mismo tratamiento + hora siempre da el mismo id.
    let mut hash: u32 = 2_166_136_261;
    for byte in tratamiento_id.bytes().chain(std::iter::once(indice as u8)) {
        hash ^= byte as u32;
        hash = hash.wrapping_mul(16_777_619);
    }
    (hash & 0x7fff_ffff) as i32
}

fn activos_con_recordatorio(app: &AppHandle) -> Result<Vec<Tratamiento>, String> {
    let estado = app.state::<AppState>();
    let conexion = estado
        .db
        .lock()
        .map_err(|_| "no se pudo acceder a la base local".to_string())?;
    db::tratamientos_con_recordatorio(&conexion).map_err(|e| e.to_string())
}
