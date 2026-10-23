/// Formateo de fechas de la interfaz.
///
/// Antes cada pantalla repetía su propio `_fecha`/`_fechaTexto`/`_fechaHora`
/// con el mismo `padLeft`. Un solo lugar evita que dos pantallas muestren la
/// misma fecha distinto (o con un cero de menos).
library;

/// Fecha de calendario como `AAAA-MM-DD` (el formato que entiende el backend).
String fechaTexto(DateTime fecha) =>
    '${fecha.year.toString().padLeft(4, '0')}-'
    '${fecha.month.toString().padLeft(2, '0')}-'
    '${fecha.day.toString().padLeft(2, '0')}';

/// Fecha y hora local como `AAAA-MM-DD HH:mm`.
String fechaHoraTexto(DateTime fecha) =>
    '${fechaTexto(fecha)} '
    '${fecha.hour.toString().padLeft(2, '0')}:'
    '${fecha.minute.toString().padLeft(2, '0')}';
