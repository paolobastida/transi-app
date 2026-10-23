import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdatos;
import 'package:timezone/timezone.dart' as tz;

import '../dominio/tratamiento.dart';
import 'base_local.dart';

/// Recordatorios locales de medicación (solo móvil; no existe en web).
///
/// Cada tratamiento activo con horas de recordatorio programa una notificación
/// **diaria** por hora ("matchDateTimeComponents: time"). Al tocar la
/// notificación se abre la app en la pantalla de tratamientos.
class RecordatorioServicio {
  final BaseLocal _base;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _listo = false;

  /// Si la app se abrió desde una notificación, indica que hay que ir a la
  /// pantalla de tratamientos (lo consume PantallaInicio al construirse).
  bool pendienteIrATratamientos = false;

  RecordatorioServicio(this._base);

  static const _canal = AndroidNotificationDetails(
    'recordatorios',
    'Recordatorios de medicación',
    channelDescription: 'Avisos para no olvidar tomar tu medicación',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const _detalles = NotificationDetails(
    android: _canal,
    iOS: DarwinNotificationDetails(),
  );

  /// Inicializa timezone, el plugin y pide permisos (no-op en web).
  Future<void> iniciar() async {
    if (kIsWeb) return;
    tzdatos.initializeTimeZones();
    try {
      final zona = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zona));
    } catch (_) {
      // Sin zona confiable: se usa la por defecto del paquete timezone.
    }
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (respuesta) {
        if (respuesta.payload == 'tratamientos') {
          pendienteIrATratamientos = true;
        }
      },
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _listo = true;
  }

  /// Pide permiso de alarmas exactas (Android 12+). Llamar desde una acción
  /// del usuario. Si se deniega, los avisos llegan igual pero pueden demorar.
  Future<void> solicitarAlarmasExactas() async {
    if (kIsWeb) return;
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
  }

  /// (Re)programa las notificaciones diarias de un tratamiento. Si no está
  /// activo o no tiene horas, cancela cualquier aviso pendiente suyo.
  Future<void> programar(Tratamiento t) async {
    if (!_listo) return;
    await cancelar(t.id);
    if (!t.activo || t.fechaFin != null || t.recordatorioMinutos.isEmpty) {
      return;
    }
    final modo = await _modoAndroid();
    for (var i = 0; i < t.recordatorioMinutos.length; i++) {
      final cuando = _proximaOcurrencia(t.recordatorioMinutos[i]);
      await _plugin.zonedSchedule(
        _idNotificacion(t.id, i),
        'Es hora de tu medicación',
        '${t.nombre} · ${t.dosis}',
        cuando,
        _detalles,
        androidScheduleMode: modo,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'tratamientos',
      );
    }
  }

  /// Cancela todas las notificaciones pendientes de un tratamiento.
  Future<void> cancelar(String tratamientoId) async {
    if (!_listo) return;
    final pendientes = await _plugin.pendingNotificationRequests();
    for (final p in pendientes) {
      if (_esDeTratamiento(p.id, tratamientoId)) {
        await _plugin.cancel(p.id);
      }
    }
  }

  /// Vuelve a programar todos los tratamientos activos con recordatorio.
  /// Cubre actualizaciones de la app y reinicios de dispositivo.
  Future<void> reprogramarTodos() async {
    if (!_listo) return;
    final filas = await _base.select(_base.tratamientos).get();
    for (final fila in filas) {
      if (!fila.activo || fila.recordatorioHoras == null) continue;
      await programar(Tratamiento(
        id: fila.id,
        usuarioId: fila.usuarioId,
        nombre: fila.nombre,
        dosis: fila.dosis,
        frecuencia: fila.frecuencia,
        fechaInicio: fila.fechaInicio,
        fechaFin: fila.fechaFin,
        activo: fila.activo,
        recordatorioMinutos: horasDesdeTexto(fila.recordatorioHoras),
      ));
    }
  }

  Future<AndroidScheduleMode> _modoAndroid() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return AndroidScheduleMode.inexactAllowWhileIdle;
    final puede = await android.canScheduleExactNotifications() ?? false;
    return puede
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  /// Próxima vez que toca esa hora del día (hoy si aún no pasó, si no mañana).
  tz.TZDateTime _proximaOcurrencia(int minutos) {
    final ahora = tz.TZDateTime.now(tz.local);
    var cuando = tz.TZDateTime(
        tz.local, ahora.year, ahora.month, ahora.day, minutos ~/ 60, minutos % 60);
    if (cuando.isBefore(ahora)) {
      cuando = cuando.add(const Duration(days: 1));
    }
    return cuando;
  }

  /// Id estable y positivo derivado del tratamiento + índice de hora.
  int _idNotificacion(String tratamientoId, int indice) =>
      (Object.hash(tratamientoId, indice) & 0x7fffffff);

  bool _esDeTratamiento(int id, String tratamientoId) {
    for (var i = 0; i < 32; i++) {
      if (_idNotificacion(tratamientoId, i) == id) return true;
    }
    return false;
  }
}
