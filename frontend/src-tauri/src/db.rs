use std::fmt;

use base64::{Engine, engine::general_purpose::STANDARD};
use rusqlite::{Connection, OptionalExtension, Row, params};
use serde_json::{Value, json};
use uuid::Uuid;

use crate::modelo::{
    Adjunto, Cambio, EntradaAdjunto, EntradaTratamiento, EventoTimeline, Tratamiento,
    horas_desde_texto, horas_texto, solo_fecha,
};

/// Error de la capa de datos, ya convertido a texto para los comandos.
#[derive(Debug)]
pub struct ErrorDb(pub String);

impl fmt::Display for ErrorDb {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(&self.0)
    }
}

impl std::error::Error for ErrorDb {}

impl From<rusqlite::Error> for ErrorDb {
    fn from(e: rusqlite::Error) -> Self {
        Self(e.to_string())
    }
}

impl From<serde_json::Error> for ErrorDb {
    fn from(e: serde_json::Error) -> Self {
        Self(e.to_string())
    }
}

impl From<base64::DecodeError> for ErrorDb {
    fn from(e: base64::DecodeError) -> Self {
        Self(format!("adjunto inválido: {e}"))
    }
}

pub type Resultado<T> = Result<T, ErrorDb>;

const ESQUEMA: &str = r#"
PRAGMA journal_mode = WAL;
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS tratamientos (
    id                       TEXT PRIMARY KEY,
    usuario_id               TEXT NOT NULL,
    nombre                   TEXT NOT NULL,
    dosis                    TEXT NOT NULL,
    frecuencia               TEXT NOT NULL,
    fecha_inicio             TEXT NOT NULL,
    fecha_fin                TEXT,
    via                      TEXT,
    presentacion             TEXT,
    dosis_cantidad           REAL,
    dosis_unidad             TEXT,
    indicacion               TEXT,
    profesional_nombre       TEXT,
    profesional_especialidad TEXT,
    activo                   INTEGER NOT NULL DEFAULT 1,
    pendiente                INTEGER NOT NULL DEFAULT 1,
    recordatorio_horas       TEXT,
    creado_en                TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS cambios (
    id          TEXT PRIMARY KEY,
    usuario_id  TEXT NOT NULL,
    fecha       TEXT NOT NULL,
    descripcion TEXT NOT NULL DEFAULT '',
    activo      INTEGER NOT NULL DEFAULT 1,
    pendiente   INTEGER NOT NULL DEFAULT 1,
    creado_en   TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS adjuntos (
    id         TEXT PRIMARY KEY,
    cambio_id  TEXT NOT NULL REFERENCES cambios(id),
    tipo       TEXT NOT NULL,
    nombre     TEXT NOT NULL DEFAULT '',
    contenido  BLOB NOT NULL,
    creado_en  TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS ajustes (
    clave TEXT PRIMARY KEY,
    valor TEXT NOT NULL
);
"#;

const COLUMNAS_TRATAMIENTO: &str = "id, usuario_id, nombre, dosis, frecuencia, \
    fecha_inicio, fecha_fin, via, presentacion, dosis_cantidad, dosis_unidad, \
    indicacion, profesional_nombre, profesional_especialidad, activo, \
    recordatorio_horas";

pub fn abrir(ruta: &std::path::Path) -> rusqlite::Result<Connection> {
    let conexion = Connection::open(ruta)?;
    conexion.execute_batch(ESQUEMA)?;
    Ok(conexion)
}

// ---------------------------------------------------------------------------
// Tratamientos
// ---------------------------------------------------------------------------

pub fn listar_tratamientos(
    conexion: &Connection,
    usuario_id: &str,
    estado: Option<&str>,
) -> Resultado<Vec<Tratamiento>> {
    listar_tratamientos_filtrados(conexion, usuario_id, estado, false)
}

/// [incluir_inactivos] lo usa el respaldo: R5 dice que nada se borra, así que
/// los registros ocultos también tienen que viajar (con `activo = false`).
fn listar_tratamientos_filtrados(
    conexion: &Connection,
    usuario_id: &str,
    estado: Option<&str>,
    incluir_inactivos: bool,
) -> Resultado<Vec<Tratamiento>> {
    let mut sql = format!("SELECT {COLUMNAS_TRATAMIENTO} FROM tratamientos WHERE usuario_id = ?1");
    if !incluir_inactivos {
        sql.push_str(" AND activo = 1");
    }
    match estado {
        Some("activo") => sql.push_str(" AND fecha_fin IS NULL"),
        Some("finalizado") => sql.push_str(" AND fecha_fin IS NOT NULL"),
        _ => {}
    }
    sql.push_str(" ORDER BY fecha_inicio DESC, creado_en DESC");

    let mut consulta = conexion.prepare(&sql)?;
    let filas = consulta.query_map(params![usuario_id], fila_a_tratamiento)?;
    let mut resultado = Vec::new();
    for fila in filas {
        resultado.push(fila?);
    }
    Ok(resultado)
}

pub fn crear_tratamiento(
    conexion: &Connection,
    usuario_id: &str,
    entrada: EntradaTratamiento,
) -> Resultado<Tratamiento> {
    let tratamiento = Tratamiento {
        id: Uuid::new_v4().to_string(),
        usuario_id: usuario_id.to_string(),
        nombre: entrada.nombre,
        dosis: entrada.dosis,
        frecuencia: entrada.frecuencia,
        fecha_inicio: solo_fecha(&entrada.fecha_inicio),
        fecha_fin: entrada.fecha_fin.map(|f| solo_fecha(&f)),
        activo: true,
        via: entrada.via,
        presentacion: entrada.presentacion,
        dosis_cantidad: entrada.dosis_cantidad,
        dosis_unidad: entrada.dosis_unidad,
        indicacion: entrada.indicacion,
        profesional_nombre: entrada.profesional_nombre,
        profesional_especialidad: entrada.profesional_especialidad,
        recordatorio_minutos: entrada.recordatorio_minutos,
    };
    insertar_tratamiento(conexion, &tratamiento)?;
    Ok(tratamiento)
}

fn insertar_tratamiento(conexion: &Connection, t: &Tratamiento) -> Resultado<()> {
    conexion.execute(
        "INSERT INTO tratamientos
         (id, usuario_id, nombre, dosis, frecuencia, fecha_inicio, fecha_fin,
          via, presentacion, dosis_cantidad, dosis_unidad, indicacion,
          profesional_nombre, profesional_especialidad, activo, pendiente,
          recordatorio_horas)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12, ?13, ?14, ?15, ?16, ?17)",
        params![
            t.id,
            t.usuario_id,
            t.nombre,
            t.dosis,
            t.frecuencia,
            t.fecha_inicio,
            t.fecha_fin,
            t.via,
            t.presentacion,
            t.dosis_cantidad,
            t.dosis_unidad,
            t.indicacion,
            t.profesional_nombre,
            t.profesional_especialidad,
            if t.activo { 1 } else { 0 },
            1,
            horas_opcionales(&t.recordatorio_minutos),
        ],
    )?;
    Ok(())
}

pub fn actualizar_tratamiento(conexion: &Connection, t: &Tratamiento) -> Resultado<()> {
    let filas = conexion.execute(
        "UPDATE tratamientos SET
            nombre = ?1, dosis = ?2, frecuencia = ?3,
            fecha_inicio = ?4, fecha_fin = ?5,
            via = ?6, presentacion = ?7, dosis_cantidad = ?8,
            dosis_unidad = ?9, indicacion = ?10,
            profesional_nombre = ?11, profesional_especialidad = ?12,
            recordatorio_horas = ?13, pendiente = 1
         WHERE id = ?14 AND usuario_id = ?15 AND activo = 1",
        params![
            t.nombre,
            t.dosis,
            t.frecuencia,
            solo_fecha(&t.fecha_inicio),
            t.fecha_fin,
            t.via,
            t.presentacion,
            t.dosis_cantidad,
            t.dosis_unidad,
            t.indicacion,
            t.profesional_nombre,
            t.profesional_especialidad,
            horas_opcionales(&t.recordatorio_minutos),
            t.id,
            t.usuario_id,
        ],
    )?;
    if filas == 0 {
        return Err(ErrorDb("el tratamiento no existe o no es tuyo".into()));
    }
    Ok(())
}

pub fn desactivar_tratamiento(conexion: &Connection, id: &str, usuario_id: &str) -> Resultado<()> {
    let filas = conexion.execute(
        "UPDATE tratamientos SET activo = 0, pendiente = 1
         WHERE id = ?1 AND usuario_id = ?2 AND activo = 1",
        params![id, usuario_id],
    )?;
    if filas == 0 {
        return Err(ErrorDb("el tratamiento no existe o no es tuyo".into()));
    }
    Ok(())
}

fn fila_a_tratamiento(fila: &Row<'_>) -> rusqlite::Result<Tratamiento> {
    Ok(Tratamiento {
        id: fila.get(0)?,
        usuario_id: fila.get(1)?,
        nombre: fila.get(2)?,
        dosis: fila.get(3)?,
        frecuencia: fila.get(4)?,
        fecha_inicio: fila.get(5)?,
        fecha_fin: fila.get(6)?,
        via: fila.get(7)?,
        presentacion: fila.get(8)?,
        dosis_cantidad: fila.get(9)?,
        dosis_unidad: fila.get(10)?,
        indicacion: fila.get(11)?,
        profesional_nombre: fila.get(12)?,
        profesional_especialidad: fila.get(13)?,
        activo: fila.get::<_, i64>(14)? != 0,
        recordatorio_minutos: horas_desde_texto(fila.get::<_, Option<String>>(15)?.as_deref()),
    })
}

fn horas_opcionales(minutos: &[i64]) -> Option<String> {
    if minutos.is_empty() {
        None
    } else {
        Some(horas_texto(minutos))
    }
}

/// Tratamientos activos con recordatorio (los lee el programador de avisos).
pub fn tratamientos_con_recordatorio(conexion: &Connection) -> Resultado<Vec<Tratamiento>> {
    let mut consulta = conexion.prepare(&format!(
        "SELECT {COLUMNAS_TRATAMIENTO} FROM tratamientos
         WHERE activo = 1 AND fecha_fin IS NULL AND recordatorio_horas IS NOT NULL"
    ))?;
    let filas = consulta.query_map([], fila_a_tratamiento)?;
    let mut resultado = Vec::new();
    for fila in filas {
        resultado.push(fila?);
    }
    Ok(resultado)
}

// ---------------------------------------------------------------------------
// Cambios y adjuntos
// ---------------------------------------------------------------------------

pub fn listar_cambios(conexion: &Connection, usuario_id: &str) -> Resultado<Vec<Cambio>> {
    listar_cambios_filtrados(conexion, usuario_id, false)
}

fn listar_cambios_filtrados(
    conexion: &Connection,
    usuario_id: &str,
    incluir_inactivos: bool,
) -> Resultado<Vec<Cambio>> {
    let mut sql = String::from(
        "SELECT id, usuario_id, fecha, descripcion, activo
         FROM cambios WHERE usuario_id = ?1",
    );
    if !incluir_inactivos {
        sql.push_str(" AND activo = 1");
    }
    sql.push_str(" ORDER BY fecha DESC, creado_en DESC");

    let mut consulta = conexion.prepare(&sql)?;
    let filas = consulta.query_map(params![usuario_id], |fila| {
        Ok(Cambio {
            id: fila.get(0)?,
            usuario_id: fila.get(1)?,
            fecha: fila.get(2)?,
            descripcion: fila.get(3)?,
            activo: fila.get::<_, i64>(4)? != 0,
            adjuntos: Vec::new(),
        })
    })?;

    let mut cambios = Vec::new();
    for fila in filas {
        let mut cambio = fila?;
        cambio.adjuntos = adjuntos_de(conexion, &cambio.id)?;
        cambios.push(cambio);
    }
    Ok(cambios)
}

fn adjuntos_de(conexion: &Connection, cambio_id: &str) -> Resultado<Vec<Adjunto>> {
    let mut consulta = conexion.prepare(
        "SELECT id, cambio_id, tipo, nombre, contenido
         FROM adjuntos WHERE cambio_id = ?1 ORDER BY creado_en",
    )?;
    let filas = consulta.query_map(params![cambio_id], |fila| {
        let contenido: Vec<u8> = fila.get(4)?;
        Ok(Adjunto {
            id: fila.get(0)?,
            cambio_id: fila.get(1)?,
            tipo: fila.get(2)?,
            nombre: fila.get(3)?,
            contenido: STANDARD.encode(contenido),
        })
    })?;
    let mut adjuntos = Vec::new();
    for fila in filas {
        adjuntos.push(fila?);
    }
    Ok(adjuntos)
}

pub fn crear_cambio(
    conexion: &mut Connection,
    usuario_id: &str,
    fecha: &str,
    descripcion: &str,
    adjuntos: Vec<EntradaAdjunto>,
) -> Resultado<Cambio> {
    let id = Uuid::new_v4().to_string();
    let fecha = solo_fecha(fecha);
    let transaccion = conexion.transaction()?;

    transaccion.execute(
        "INSERT INTO cambios (id, usuario_id, fecha, descripcion, activo, pendiente)
         VALUES (?1, ?2, ?3, ?4, 1, 1)",
        params![id, usuario_id, fecha, descripcion],
    )?;

    let mut guardados = Vec::new();
    for entrada in adjuntos {
        let adjunto_id = Uuid::new_v4().to_string();
        let contenido = STANDARD.decode(&entrada.contenido)?;
        transaccion.execute(
            "INSERT INTO adjuntos (id, cambio_id, tipo, nombre, contenido)
             VALUES (?1, ?2, ?3, ?4, ?5)",
            params![adjunto_id, id, entrada.tipo, entrada.nombre, contenido],
        )?;
        guardados.push(Adjunto {
            id: adjunto_id,
            cambio_id: id.clone(),
            tipo: entrada.tipo,
            nombre: entrada.nombre,
            contenido: entrada.contenido,
        });
    }

    transaccion.commit()?;
    Ok(Cambio {
        id,
        usuario_id: usuario_id.to_string(),
        fecha,
        descripcion: descripcion.to_string(),
        activo: true,
        adjuntos: guardados,
    })
}

pub fn desactivar_cambio(conexion: &Connection, id: &str, usuario_id: &str) -> Resultado<()> {
    let filas = conexion.execute(
        "UPDATE cambios SET activo = 0, pendiente = 1
         WHERE id = ?1 AND usuario_id = ?2 AND activo = 1",
        params![id, usuario_id],
    )?;
    if filas == 0 {
        return Err(ErrorDb("el cambio no existe o no es tuyo".into()));
    }
    Ok(())
}

// ---------------------------------------------------------------------------
// Línea de tiempo (consulta de lectura: no hay tabla propia)
// ---------------------------------------------------------------------------

pub fn linea_de_tiempo(
    conexion: &Connection,
    usuario_id: &str,
    desde: Option<&str>,
    hasta: Option<&str>,
) -> Resultado<Vec<EventoTimeline>> {
    let mut eventos = Vec::new();

    for tratamiento in listar_tratamientos(conexion, usuario_id, None)? {
        eventos.push(EventoTimeline {
            tipo: "tratamiento".into(),
            fecha: tratamiento.fecha_inicio.clone(),
            titulo: tratamiento.nombre.clone(),
            detalle: detalle_tratamiento(&tratamiento),
            referencia_id: tratamiento.id.clone(),
        });
    }

    for cambio in listar_cambios(conexion, usuario_id)? {
        eventos.push(EventoTimeline {
            tipo: "cambio".into(),
            fecha: cambio.fecha.clone(),
            titulo: if cambio.descripcion.is_empty() {
                "Cambio".into()
            } else {
                cambio.descripcion.clone()
            },
            detalle: resumen_adjuntos(&cambio),
            referencia_id: cambio.id.clone(),
        });
    }

    eventos.retain(|evento| {
        desde.is_none_or(|d| evento.fecha.as_str() >= d)
            && hasta.is_none_or(|h| evento.fecha.as_str() <= h)
    });
    eventos.sort_by(|a, b| b.fecha.cmp(&a.fecha));
    Ok(eventos)
}

fn detalle_tratamiento(t: &Tratamiento) -> String {
    let mut partes = vec![t.dosis.clone()];
    if let Some(via) = &t.via {
        partes.push(via.clone());
    }
    partes.push(t.frecuencia.clone());
    partes.join(" · ")
}

fn resumen_adjuntos(cambio: &Cambio) -> String {
    if cambio.adjuntos.is_empty() {
        return "Sin adjuntos".into();
    }
    let fotos = cambio.adjuntos.iter().filter(|a| a.tipo == "foto").count();
    let audios = cambio.adjuntos.iter().filter(|a| a.tipo == "audio").count();
    let mut partes = Vec::new();
    if fotos > 0 {
        partes.push(format!("{fotos} foto(s)"));
    }
    if audios > 0 {
        partes.push(format!("{audios} audio(s)"));
    }
    partes.join(" · ")
}

// ---------------------------------------------------------------------------
// Respaldos
// ---------------------------------------------------------------------------

pub fn pendientes(conexion: &Connection, usuario_id: &str) -> Resultado<i64> {
    let tratamientos: i64 = conexion.query_row(
        "SELECT COUNT(*) FROM tratamientos WHERE usuario_id = ?1 AND pendiente = 1",
        params![usuario_id],
        |fila| fila.get(0),
    )?;
    let cambios: i64 = conexion.query_row(
        "SELECT COUNT(*) FROM cambios WHERE usuario_id = ?1 AND pendiente = 1",
        params![usuario_id],
        |fila| fila.get(0),
    )?;
    Ok(tratamientos + cambios)
}

pub fn ultimo_respaldo(conexion: &Connection) -> Resultado<Option<String>> {
    Ok(conexion
        .query_row(
            "SELECT valor FROM ajustes WHERE clave = 'ultimo_respaldo_en'",
            [],
            |fila| fila.get(0),
        )
        .optional()?)
}

/// Arma el snapshot completo (mismo formato que la app Flutter).
pub fn snapshot(conexion: &Connection, usuario_id: &str) -> Resultado<Value> {
    let tratamientos: Vec<Value> = listar_tratamientos_filtrados(conexion, usuario_id, None, true)?
        .into_iter()
        .map(|t| {
            json!({
                "id": t.id,
                "nombre": t.nombre,
                "dosis": t.dosis,
                "frecuencia": t.frecuencia,
                "fechaInicio": format!("{}T00:00:00.000", t.fecha_inicio),
                "fechaFin": t.fecha_fin.map(|f| format!("{f}T00:00:00.000")),
                "activo": t.activo,
                "via": t.via,
                "presentacion": t.presentacion,
                "dosisCantidad": t.dosis_cantidad,
                "dosisUnidad": t.dosis_unidad,
                "indicacion": t.indicacion,
                "profesionalNombre": t.profesional_nombre,
                "profesionalEspecialidad": t.profesional_especialidad,
                "recordatorioMinutos": t.recordatorio_minutos,
            })
        })
        .collect();

    let cambios: Vec<Value> = listar_cambios_filtrados(conexion, usuario_id, true)?
        .into_iter()
        .map(|c| {
            json!({
                "id": c.id,
                "fecha": format!("{}T00:00:00.000", c.fecha),
                "descripcion": c.descripcion,
                "activo": c.activo,
                "adjuntos": c.adjuntos.into_iter().map(|a| json!({
                    "id": a.id,
                    "tipo": a.tipo,
                    "nombre": a.nombre,
                    "contenido": a.contenido,
                })).collect::<Vec<_>>(),
            })
        })
        .collect();

    Ok(json!({
        "version": 2,
        "generadoEn": chrono::Utc::now().to_rfc3339_opts(chrono::SecondsFormat::Millis, true),
        "tratamientos": tratamientos,
        "cambios": cambios,
    }))
}

pub fn reemplazar_todo(
    conexion: &mut Connection,
    usuario_id: &str,
    snapshot: &Value,
) -> Resultado<()> {
    let transaccion = conexion.transaction()?;
    transaccion.execute("DELETE FROM adjuntos", [])?;
    transaccion.execute("DELETE FROM cambios", [])?;
    transaccion.execute("DELETE FROM tratamientos", [])?;

    if let Some(lista) = snapshot.get("tratamientos").and_then(Value::as_array) {
        for crudo in lista {
            let minutos: Vec<i64> = crudo
                .get("recordatorioMinutos")
                .and_then(Value::as_array)
                .map(|a| a.iter().filter_map(Value::as_i64).collect())
                .unwrap_or_default();
            transaccion.execute(
                "INSERT INTO tratamientos
                 (id, usuario_id, nombre, dosis, frecuencia, fecha_inicio, fecha_fin,
                  via, presentacion, dosis_cantidad, dosis_unidad, indicacion,
                  profesional_nombre, profesional_especialidad, activo, pendiente,
                  recordatorio_horas)
                 VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12, ?13, ?14, ?15, 0, ?16)",
                params![
                    texto(crudo, "id"),
                    usuario_id,
                    texto(crudo, "nombre"),
                    texto(crudo, "dosis"),
                    texto(crudo, "frecuencia"),
                    solo_fecha(&texto(crudo, "fechaInicio")),
                    opcional(crudo, "fechaFin").map(|f| solo_fecha(&f)),
                    opcional(crudo, "via"),
                    opcional(crudo, "presentacion"),
                    crudo.get("dosisCantidad").and_then(Value::as_f64),
                    opcional(crudo, "dosisUnidad"),
                    opcional(crudo, "indicacion"),
                    opcional(crudo, "profesionalNombre"),
                    opcional(crudo, "profesionalEspecialidad"),
                    if booleano(crudo, "activo") { 1 } else { 0 },
                    horas_opcionales(&minutos),
                ],
            )?;
        }
    }

    if let Some(lista) = snapshot.get("cambios").and_then(Value::as_array) {
        for crudo in lista {
            let cambio_id = texto(crudo, "id");
            transaccion.execute(
                "INSERT INTO cambios (id, usuario_id, fecha, descripcion, activo, pendiente)
                 VALUES (?1, ?2, ?3, ?4, ?5, 0)",
                params![
                    cambio_id,
                    usuario_id,
                    solo_fecha(&texto(crudo, "fecha")),
                    texto(crudo, "descripcion"),
                    if booleano(crudo, "activo") { 1 } else { 0 },
                ],
            )?;

            if let Some(adjuntos) = crudo.get("adjuntos").and_then(Value::as_array) {
                for adjunto in adjuntos {
                    transaccion.execute(
                        "INSERT INTO adjuntos (id, cambio_id, tipo, nombre, contenido)
                         VALUES (?1, ?2, ?3, ?4, ?5)",
                        params![
                            texto(adjunto, "id"),
                            cambio_id,
                            texto(adjunto, "tipo"),
                            texto(adjunto, "nombre"),
                            STANDARD.decode(texto(adjunto, "contenido"))?,
                        ],
                    )?;
                }
            }
        }
    }

    transaccion.commit()?;
    Ok(())
}

pub fn marcar_respaldado(conexion: &mut Connection, usuario_id: &str) -> Resultado<()> {
    let transaccion = conexion.transaction()?;
    transaccion.execute(
        "UPDATE tratamientos SET pendiente = 0 WHERE usuario_id = ?1 AND pendiente = 1",
        params![usuario_id],
    )?;
    transaccion.execute(
        "UPDATE cambios SET pendiente = 0 WHERE usuario_id = ?1 AND pendiente = 1",
        params![usuario_id],
    )?;
    transaccion.execute(
        "INSERT INTO ajustes (clave, valor) VALUES ('ultimo_respaldo_en', ?1)
         ON CONFLICT(clave) DO UPDATE SET valor = excluded.valor",
        params![chrono::Utc::now().to_rfc3339_opts(chrono::SecondsFormat::Millis, true)],
    )?;
    transaccion.commit()?;
    Ok(())
}

/// Borra todos los datos locales de salud (al cerrar sesión).
pub fn purgar(conexion: &mut Connection) -> Resultado<()> {
    let transaccion = conexion.transaction()?;
    transaccion.execute("DELETE FROM adjuntos", [])?;
    transaccion.execute("DELETE FROM cambios", [])?;
    transaccion.execute("DELETE FROM tratamientos", [])?;
    transaccion.commit()?;
    Ok(())
}

fn texto(valor: &Value, clave: &str) -> String {
    valor
        .get(clave)
        .and_then(Value::as_str)
        .unwrap_or_default()
        .to_string()
}

fn opcional(valor: &Value, clave: &str) -> Option<String> {
    valor
        .get(clave)
        .and_then(Value::as_str)
        .map(str::trim)
        .filter(|v| !v.is_empty())
        .map(str::to_string)
}

fn booleano(valor: &Value, clave: &str) -> bool {
    valor.get(clave).and_then(Value::as_bool).unwrap_or(true)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn conexion() -> Connection {
        let conexion = Connection::open_in_memory().unwrap();
        conexion.execute_batch(ESQUEMA).unwrap();
        conexion
    }

    fn entrada(nombre: &str) -> EntradaTratamiento {
        EntradaTratamiento {
            nombre: nombre.into(),
            dosis: "2 mg".into(),
            frecuencia: "cada día".into(),
            fecha_inicio: "2026-01-01".into(),
            fecha_fin: None,
            via: None,
            presentacion: None,
            dosis_cantidad: None,
            dosis_unidad: None,
            indicacion: None,
            profesional_nombre: None,
            profesional_especialidad: None,
            recordatorio_minutos: vec![],
        }
    }

    #[test]
    fn el_respaldo_incluye_registros_ocultos_y_los_restaura() {
        let mut origen = conexion();
        let tratamiento = crear_tratamiento(&origen, "u1", entrada("Estradiol")).unwrap();
        desactivar_tratamiento(&origen, &tratamiento.id, "u1").unwrap();
        let cambio = crear_cambio(&mut origen, "u1", "2026-01-10", "nota", vec![]).unwrap();
        desactivar_cambio(&origen, &cambio.id, "u1").unwrap();

        let snapshot = snapshot(&origen, "u1").unwrap();
        assert_eq!(snapshot["tratamientos"].as_array().unwrap().len(), 1);
        assert_eq!(snapshot["cambios"].as_array().unwrap().len(), 1);
        assert_eq!(snapshot["tratamientos"][0]["activo"], false);

        let mut destino = conexion();
        reemplazar_todo(&mut destino, "u1", &snapshot).unwrap();
        assert!(
            listar_tratamientos(&destino, "u1", None)
                .unwrap()
                .is_empty()
        );
        let todos = listar_tratamientos_filtrados(&destino, "u1", None, true).unwrap();
        assert_eq!(todos.len(), 1);
        assert!(!todos[0].activo);
    }

    #[test]
    fn la_linea_de_tiempo_une_y_filtra() {
        let mut base = conexion();
        crear_tratamiento(&base, "u1", entrada("Estradiol")).unwrap();
        crear_cambio(&mut base, "u1", "2026-02-01", "voz", vec![]).unwrap();

        let todos = linea_de_tiempo(&base, "u1", None, None).unwrap();
        assert_eq!(todos.len(), 2);
        assert_eq!(todos[0].fecha, "2026-02-01");

        let solo_enero =
            linea_de_tiempo(&base, "u1", Some("2026-01-01"), Some("2026-01-31")).unwrap();
        assert_eq!(solo_enero.len(), 1);
        assert_eq!(solo_enero[0].tipo, "tratamiento");
    }
}
