import Foundation
import UserNotifications
import WebKit

/// Log a stderr sin buffering: los `print` redirigidos a archivo se pierden al
/// terminar el proceso desde la terminal.
private func logRecordatorios(_ mensaje: String) {
    FileHandle.standardError.write(Data(("[recordatorios] \(mensaje)\n").utf8))
}

/// Puente entre el webview y las notificaciones programadas del sistema.
///
/// El JS envía `{ accion, solicitudId?, recordatorios? }` por el handler
/// `recordatorios` y recibe la respuesta en
/// `window.__transiRecordatoriosRecibir(json)`.
///
/// Los avisos se agendan con `UNCalendarNotificationTrigger(repeats: true)`, así
/// que los entrega macOS aunque Transi esté cerrada.
final class Recordatorios: NSObject, WKScriptMessageHandler, UNUserNotificationCenterDelegate {
    static let nombreMensaje = "recordatorios"
    static let prefijo = "transi.recordatorio."

    private weak var webView: WKWebView?

    private struct Programado {
        let id: String
        let titulo: String
        let cuerpo: String
        let hora: Int
        let minuto: Int
        /// Días concretos "AAAA-MM-DD" cuando la frecuencia no es diaria.
        /// Vacío = aviso diario que se repite, como hasta ahora.
        let fechas: [String]
    }

    /// Conecta el webview y queda como delegado de las notificaciones.
    /// No pide permiso acá: eso ocurre desde una acción del usuario.
    func conectar(_ webView: WKWebView) {
        self.webView = webView
        UNUserNotificationCenter.current().delegate = self
        logRecordatorios("puente conectado")
    }

    // MARK: - Mensajes del webview

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.name == Self.nombreMensaje,
            let cuerpo = message.body as? [String: Any]
        else { return }

        let solicitudId = cuerpo["solicitudId"] as? String
        switch cuerpo["accion"] as? String {
        case "sincronizar":
            let crudos = cuerpo["recordatorios"] as? [[String: Any]] ?? []
            sincronizar(crudos)
        case "permiso":
            pedirPermiso(solicitudId: solicitudId)
        case "estado":
            estado(solicitudId: solicitudId)
        case "probar":
            probar(solicitudId: solicitudId)
        default:
            responder(solicitudId: solicitudId, ok: false, error: "acción desconocida")
        }
    }

    // MARK: - Programación

    private func sincronizar(_ crudos: [[String: Any]]) {
        let centro = UNUserNotificationCenter.current()
        let validos = crudos.compactMap(programadoValido)

        centro.getPendingNotificationRequests { existentes in
            // Solo tocamos los avisos de Transi: una app no debería borrar los
            // de otras, aunque en la práctica sea la única que agenda.
            let anteriores = existentes
                .map(\.identifier)
                .filter { $0.hasPrefix(Self.prefijo) }
            centro.removePendingNotificationRequests(withIdentifiers: anteriores)

            for aviso in validos {
                if aviso.fechas.isEmpty {
                    let contenido = UNMutableNotificationContent()
                    contenido.title = aviso.titulo
                    contenido.body = aviso.cuerpo
                    contenido.sound = .default

                    var componentes = DateComponents()
                    componentes.hour = aviso.hora
                    componentes.minute = aviso.minuto

                    let disparador = UNCalendarNotificationTrigger(
                        dateMatching: componentes, repeats: true)
                    let solicitud = UNNotificationRequest(
                        identifier: aviso.id, content: contenido, trigger: disparador)
                    centro.add(solicitud) { error in
                        if let error {
                            logRecordatorios("no se pudo programar \(aviso.id): \(error)")
                        }
                    }
                } else {
                    // Frecuencia no diaria: un aviso puntual por fecha y sin
                    // repetir. "cada 7 días" no debe sonar todos los días.
                    for fecha in aviso.fechas {
                        guard
                            let componentes = Self.componentesFecha(
                                fecha, hora: aviso.hora, minuto: aviso.minuto)
                        else { continue }

                        let identificador = "\(aviso.id).\(fecha)"
                        guard identificador.count <= 200 else { continue }

                        let contenido = UNMutableNotificationContent()
                        contenido.title = aviso.titulo
                        contenido.body = aviso.cuerpo
                        contenido.sound = .default

                        let disparador = UNCalendarNotificationTrigger(
                            dateMatching: componentes, repeats: false)
                        let solicitud = UNNotificationRequest(
                            identifier: identificador, content: contenido, trigger: disparador)
                        centro.add(solicitud) { error in
                            if let error {
                                logRecordatorios(
                                    "no se pudo programar \(identificador): \(error)")
                            }
                        }
                    }
                }
            }

            logRecordatorios("programados \(validos.count)")
        }
    }

    private func programadoValido(_ crudo: [String: Any]) -> Programado? {
        guard let id = crudo["id"] as? String, !id.isEmpty,
            let titulo = crudo["titulo"] as? String,
            let cuerpo = crudo["cuerpo"] as? String,
            let hora = crudo["hora"] as? Int, (0...23).contains(hora),
            let minuto = crudo["minuto"] as? Int, (0...59).contains(minuto)
        else { return nil }

        let identificador = id.hasPrefix(Self.prefijo) ? id : Self.prefijo + id
        guard identificador.count <= 200 else { return nil }

        // El JS solo envía fechas reales (itera días de calendario); acá se
        // valida el formato y se acota la cantidad por seguridad.
        let fechas = (crudo["fechas"] as? [String] ?? []).filter { Self.componentesFecha($0) != nil }
        guard fechas.count <= 400 else { return nil }

        return Programado(
            id: identificador, titulo: titulo, cuerpo: cuerpo, hora: hora,
            minuto: minuto, fechas: fechas)
    }

    /// `"AAAA-MM-DD"` (más hora y minuto opcionales) a componentes locales.
    private static func componentesFecha(
        _ fecha: String, hora: Int? = nil, minuto: Int? = nil
    ) -> DateComponents? {
        let partes = fecha.split(separator: "-")
        guard partes.count == 3,
            let anio = Int(partes[0]), let mes = Int(partes[1]), let dia = Int(partes[2]),
            anio > 0, (1...12).contains(mes), (1...31).contains(dia)
        else { return nil }

        var componentes = DateComponents()
        componentes.year = anio
        componentes.month = mes
        componentes.day = dia
        if let hora { componentes.hour = hora }
        if let minuto { componentes.minute = minuto }
        return componentes
    }

    // MARK: - Permiso y estado

    private func pedirPermiso(solicitudId: String?) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { [weak self] _, _ in
            self?.estado(solicitudId: solicitudId)
        }
    }

    private func estado(solicitudId: String?) {
        let centro = UNUserNotificationCenter.current()
        centro.getNotificationSettings { [weak self] ajustes in
            let permiso = Self.textoPermiso(ajustes.authorizationStatus)
            centro.getPendingNotificationRequests { solicitudes in
                let programados = solicitudes.filter {
                    $0.identifier.hasPrefix(Self.prefijo)
                }.count
                self?.responder(
                    solicitudId: solicitudId, ok: true, permiso: permiso,
                    programados: programados)
            }
        }
    }

    private static func textoPermiso(_ estado: UNAuthorizationStatus) -> String {
        switch estado {
        case .authorized: return "concedido"
        case .denied: return "denegado"
        case .notDetermined: return "sin-solicitar"
        default: return "no-soportado"
        }
    }

    // MARK: - Aviso de prueba

    private func probar(solicitudId: String?) {
        let centro = UNUserNotificationCenter.current()
        centro.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] _, _ in
            let contenido = UNMutableNotificationContent()
            contenido.title = "Prueba de recordatorio"
            contenido.body = "Si ves este aviso, los recordatorios programados funcionan."
            contenido.sound = .default

            let disparador = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
            let solicitud = UNNotificationRequest(
                identifier: Self.prefijo + "prueba", content: contenido, trigger: disparador)
            centro.add(solicitud) { error in
                if let error {
                    logRecordatorios("la prueba falló: \(error)")
                }
                self?.estado(solicitudId: solicitudId)
            }
        }
    }

    /// Verifica la ruta completa de sincronización con una lista de ejemplo.
    func probarSincronizarDesdeCLI() {
        let crudos: [[String: Any]] = [
            [
                "id": "transi.recordatorio.prueba.sincronizar",
                "titulo": "Prueba programada",
                "cuerpo": "Aviso diario de prueba",
                "hora": 8,
                "minuto": 0,
            ]
        ]
        sincronizar(crudos)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            UNUserNotificationCenter.current().getPendingNotificationRequests { solicitudes in
                let nuestras = solicitudes
                    .map(\.identifier)
                    .filter { $0.hasPrefix(Self.prefijo) }
                logRecordatorios("CLI sincronizados: \(nuestras)")
            }
        }
    }

    /// Permite probar la programación desde la línea de comandos:
    /// `Transi.app/Contents/MacOS/Transi --probar-recordatorio`
    ///
    /// No espera la autorización: sirve para verificar que macOS acepta la
    /// solicitud y la deja pendiente. La entrega visible depende de que el
    /// usuario haya concedido las notificaciones.
    func probarDesdeCLI() {
        let centro = UNUserNotificationCenter.current()
        let contenido = UNMutableNotificationContent()
        contenido.title = "Prueba de recordatorio"
        contenido.body = "Solicitud programada desde la línea de comandos."
        contenido.sound = .default

        let disparador = UNTimeIntervalNotificationTrigger(timeInterval: 30, repeats: false)
        let solicitud = UNNotificationRequest(
            identifier: Self.prefijo + "prueba-cli", content: contenido, trigger: disparador)
        centro.add(solicitud) { error in
            if let error {
                logRecordatorios("CLI: no se pudo programar: \(error)")
                return
            }
            centro.getNotificationSettings { ajustes in
                logRecordatorios("CLI permiso: \(ajustes.authorizationStatus.rawValue)")
            }
            centro.getPendingNotificationRequests { solicitudes in
                let nuestras = solicitudes
                    .map(\.identifier)
                    .filter { $0.hasPrefix(Self.prefijo) }
                logRecordatorios("CLI pendientes: \(nuestras)")
            }
        }
    }

    // MARK: - Respuesta al webview

    private func responder(
        solicitudId: String?, ok: Bool, error: String? = nil, permiso: String? = nil,
        programados: Int? = nil
    ) {
        var respuesta: [String: Any] = ["ok": ok]
        if let solicitudId { respuesta["solicitudId"] = solicitudId }
        if let error { respuesta["error"] = error }
        if let permiso { respuesta["permiso"] = permiso }
        if let programados { respuesta["programados"] = programados }

        guard let datos = try? JSONSerialization.data(withJSONObject: respuesta),
            let json = String(data: datos, encoding: .utf8)
        else { return }

        DispatchQueue.main.async { [weak self] in
            self?.webView?.evaluateJavaScript(
                "window.__transiRecordatoriosRecibir(\(json));")
        }
    }

    // MARK: - Con la app abierta

    func userNotificationCenter(
        _ center: UNUserNotificationCenter, willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
