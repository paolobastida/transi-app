use serde::{Deserialize, Serialize};

fn activo_por_defecto() -> bool {
    true
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Usuario {
    pub id: String,
    pub email: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Tratamiento {
    pub id: String,
    pub usuario_id: String,
    pub nombre: String,
    pub dosis: String,
    pub frecuencia: String,
    /// Fecha de calendario `AAAA-MM-DD`.
    pub fecha_inicio: String,
    pub fecha_fin: Option<String>,
    #[serde(default = "activo_por_defecto")]
    pub activo: bool,
    pub via: Option<String>,
    pub presentacion: Option<String>,
    pub dosis_cantidad: Option<f64>,
    pub dosis_unidad: Option<String>,
    pub indicacion: Option<String>,
    pub profesional_nombre: Option<String>,
    pub profesional_especialidad: Option<String>,
    /// Horas del recordatorio diario, en minutos desde medianoche.
    #[serde(default)]
    pub recordatorio_minutos: Vec<i64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct EntradaTratamiento {
    pub nombre: String,
    pub dosis: String,
    pub frecuencia: String,
    pub fecha_inicio: String,
    pub fecha_fin: Option<String>,
    pub via: Option<String>,
    pub presentacion: Option<String>,
    pub dosis_cantidad: Option<f64>,
    pub dosis_unidad: Option<String>,
    pub indicacion: Option<String>,
    pub profesional_nombre: Option<String>,
    pub profesional_especialidad: Option<String>,
    #[serde(default)]
    pub recordatorio_minutos: Vec<i64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct EntradaAdjunto {
    pub tipo: String,
    pub nombre: String,
    /// Contenido en base64 (viene así desde el webview).
    pub contenido: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Adjunto {
    pub id: String,
    pub cambio_id: String,
    pub tipo: String,
    pub nombre: String,
    /// Contenido en base64 (se devuelve así al webview).
    pub contenido: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Cambio {
    pub id: String,
    pub usuario_id: String,
    pub fecha: String,
    pub descripcion: String,
    #[serde(default = "activo_por_defecto")]
    pub activo: bool,
    #[serde(default)]
    pub adjuntos: Vec<Adjunto>,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct EventoTimeline {
    /// `"tratamiento"` o `"cambio"`.
    pub tipo: String,
    pub fecha: String,
    pub titulo: String,
    pub detalle: String,
    pub referencia_id: String,
}

/// Convierte minutos desde medianoche en `"HH:mm"`.
pub fn hora_texto(minutos: i64) -> String {
    format!("{:02}:{:02}", minutos / 60, minutos % 60)
}

/// Serializa los minutos de recordatorio como `"08:00,20:00"`.
pub fn horas_texto(minutos: &[i64]) -> String {
    minutos
        .iter()
        .map(|m| hora_texto(*m))
        .collect::<Vec<_>>()
        .join(",")
}

/// Parsea `"08:00,20:00"` a minutos, descartando lo inválido y ordenando.
pub fn horas_desde_texto(texto: Option<&str>) -> Vec<i64> {
    let Some(texto) = texto else {
        return Vec::new();
    };
    let mut minutos: Vec<i64> = texto
        .split(',')
        .filter_map(|parte| {
            let (h, m) = parte.trim().split_once(':')?;
            let h: i64 = h.parse().ok()?;
            let m: i64 = m.parse().ok()?;
            (h <= 23 && m <= 59).then_some(h * 60 + m)
        })
        .collect();
    minutos.sort_unstable();
    minutos.dedup();
    minutos
}

/// Normaliza una fecha ISO (`2026-01-10T00:00:00.000`) a `AAAA-MM-DD`.
pub fn solo_fecha(valor: &str) -> String {
    valor.get(..10).unwrap_or(valor).to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn horas_ida_y_vuelta() {
        let minutos = vec![480, 1200];
        assert_eq!(horas_texto(&minutos), "08:00,20:00");
        assert_eq!(horas_desde_texto(Some("20:00,08:00")), minutos);
        assert!(horas_desde_texto(Some("99:99, basura")).is_empty());
        assert!(horas_desde_texto(None).is_empty());
    }

    #[test]
    fn solo_fecha_normaliza_iso() {
        assert_eq!(solo_fecha("2026-01-10T00:00:00.000"), "2026-01-10");
        assert_eq!(solo_fecha("2026-01-10"), "2026-01-10");
    }
}
