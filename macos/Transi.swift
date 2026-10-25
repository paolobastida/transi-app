import Cocoa
import Network
import WebKit

/// Servidor HTTP mínimo para servir `dist/` dentro del bundle de la app.
/// Usa un puerto efímero en 127.0.0.1 y no expone nada fuera de la máquina.
final class LocalHTTPServer {
    enum ServerError: Error {
        case couldNotStart
    }

    /// Puerto fijo: mantiene estable el origen de localStorage entre arranques.
    static let preferredPort: UInt16 = 47615

    private let root: URL
    private var listener: NWListener?
    private let queue = DispatchQueue(label: "com.transi.local-server")
    private(set) var port: UInt16 = 0

    init(root: URL) {
        self.root = root
    }

    func start() throws -> UInt16 {
        guard let preferred = NWEndpoint.Port(rawValue: Self.preferredPort) else {
            throw ServerError.couldNotStart
        }
        let parameters = NWParameters.tcp
        parameters.requiredLocalEndpoint = .hostPort(
            host: NWEndpoint.Host("127.0.0.1"), port: preferred)
        let listener = try NWListener(using: parameters)
        self.listener = listener

        var started = false
        let ready = DispatchSemaphore(value: 0)
        listener.stateUpdateHandler = { state in
            switch state {
            case .ready:
                started = true
                ready.signal()
            case .failed, .cancelled:
                ready.signal()
            default:
                break
            }
        }
        listener.newConnectionHandler = { [weak self] connection in
            self?.accept(connection)
        }
        listener.start(queue: queue)

        _ = ready.wait(timeout: .now() + 5)
        guard started else {
            listener.cancel()
            throw ServerError.couldNotStart
        }
        port = Self.preferredPort
        return Self.preferredPort
    }

    private func accept(_ connection: NWConnection) {
        // El listener queda accesible en la red local; solo atendemos loopback.
        if case let .hostPort(host, _) = connection.endpoint {
            let remote = "\(host)"
            let esLocal =
                remote == "127.0.0.1" || remote == "::1" || remote == "::ffff:127.0.0.1"
            if !esLocal {
                connection.cancel()
                return
            }
        }
        connection.start(queue: queue)
        receive(connection, accumulated: Data())
    }

    private func receive(_ connection: NWConnection, accumulated: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1024) {
            [weak self] data, _, complete, error in
            guard let self else {
                connection.cancel()
                return
            }

            var buffer = accumulated
            if let data {
                buffer.append(data)
            }

            if buffer.range(of: Data("\r\n\r\n".utf8)) != nil {
                self.respond(connection, request: buffer)
            } else if error != nil || complete || buffer.count > 1_000_000 {
                connection.cancel()
            } else {
                self.receive(connection, accumulated: buffer)
            }
        }
    }

    private func respond(_ connection: NWConnection, request: Data) {
        let text = String(decoding: request, as: UTF8.self)
        let firstLine = text.components(separatedBy: "\r\n").first ?? ""
        let parts = firstLine.split(separator: " ")

        var path = parts.count > 1 ? String(parts[1]) : "/"
        if let query = path.firstIndex(of: "?") {
            path = String(path[..<query])
        }
        path = path.removingPercentEncoding ?? path
        if path.isEmpty || path == "/" {
            path = "/index.html"
        }

        // Evita salir del directorio de la app.
        let segments = path.split(separator: "/").map(String.init).filter {
            $0 != "." && $0 != ".."
        }
        let file = root.appendingPathComponent(segments.joined(separator: "/"))
        let content = (try? Data(contentsOf: file)) ?? Data()
        let found = !content.isEmpty
        let body = found ? content : Data("No encontrado".utf8)
        let mime = found ? Self.mimeType(file.pathExtension) : "text/plain; charset=utf-8"
        let status = found ? "200 OK" : "404 Not Found"
        let headers =
            "HTTP/1.1 \(status)\r\n"
            + "Content-Type: \(mime)\r\n"
            + "Content-Length: \(body.count)\r\n"
            + "Cache-Control: no-cache\r\n"
            + "Connection: close\r\n"
            + "\r\n"

        var response = Data(headers.utf8)
        response.append(body)
        connection.send(content: response, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    private static func mimeType(_ fileExtension: String) -> String {
        switch fileExtension.lowercased() {
        case "html", "htm": return "text/html; charset=utf-8"
        case "js", "mjs": return "text/javascript; charset=utf-8"
        case "css": return "text/css; charset=utf-8"
        case "json": return "application/json; charset=utf-8"
        case "webmanifest": return "application/manifest+json; charset=utf-8"
        case "svg": return "image/svg+xml"
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "webp": return "image/webp"
        case "ico": return "image/x-icon"
        case "woff2": return "font/woff2"
        case "mp4": return "video/mp4"
        case "webm": return "audio/webm"
        default: return "application/octet-stream"
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate, WKUIDelegate,
    WKDownloadDelegate
{
    private var window: NSWindow?
    private var webView: WKWebView?
    private var server: LocalHTTPServer?
    private var recordatorios: Recordatorios?

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMenu()

        guard let resources = Bundle.main.resourceURL else {
            NSApp.terminate(nil)
            return
        }

        let server = LocalHTTPServer(root: resources.appendingPathComponent("dist"))
        do {
            let port = try server.start()
            self.server = server

            let configuration = WKWebViewConfiguration()
            configuration.defaultWebpagePreferences.allowsContentJavaScript = true
            configuration.mediaTypesRequiringUserActionForPlayback = []

            // Puente para programar notificaciones en el sistema (UserNotifications).
            let recordatorios = Recordatorios()
            configuration.userContentController.add(
                recordatorios, name: Recordatorios.nombreMensaje)
            self.recordatorios = recordatorios

            let webView = WKWebView(frame: .zero, configuration: configuration)
            webView.navigationDelegate = self
            webView.uiDelegate = self
            webView.allowsMagnification = false
            recordatorios.conectar(webView)
            self.webView = webView

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1180, height: 820),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Transi"
            window.minSize = NSSize(width: 380, height: 560)
            window.backgroundColor = NSColor(
                calibratedRed: 0.969, green: 0.984, blue: 0.992, alpha: 1)
            window.contentView = webView
            window.center()
            window.makeKeyAndOrderFront(nil)
            self.window = window

            NSApp.activate(ignoringOtherApps: true)
            webView.load(URLRequest(url: URL(string: "http://127.0.0.1:\(port)/")!))

            if CommandLine.arguments.contains("--probar-recordatorio") {
                recordatorios.probarDesdeCLI()
            }
            if CommandLine.arguments.contains("--probar-sincronizados") {
                recordatorios.probarSincronizarDesdeCLI()
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = "No se pudo iniciar Transi"
            alert.informativeText = "No pudimos levantar el servidor local de la app."
            alert.runModal()
            NSApp.terminate(nil)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    // MARK: - Diálogos de JavaScript

    func webView(
        _ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void
    ) {
        guard let window else {
            completionHandler()
            return
        }
        let alert = NSAlert()
        alert.messageText = "Transi"
        alert.informativeText = message
        alert.addButton(withTitle: "Aceptar")
        alert.beginSheetModal(for: window) { _ in completionHandler() }
    }

    func webView(
        _ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void
    ) {
        guard let window else {
            completionHandler(false)
            return
        }
        let alert = NSAlert()
        alert.messageText = "Transi"
        alert.informativeText = message
        alert.addButton(withTitle: "Aceptar")
        alert.addButton(withTitle: "Cancelar")
        alert.beginSheetModal(for: window) { response in
            completionHandler(response == .alertFirstButtonReturn)
        }
    }

    func webView(
        _ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?, initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (String?) -> Void
    ) {
        guard let window else {
            completionHandler(nil)
            return
        }
        let alert = NSAlert()
        alert.messageText = "Transi"
        alert.informativeText = prompt
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 280, height: 24))
        field.stringValue = defaultText ?? ""
        alert.accessoryView = field
        alert.addButton(withTitle: "Aceptar")
        alert.addButton(withTitle: "Cancelar")
        alert.beginSheetModal(for: window) { response in
            completionHandler(response == .alertFirstButtonReturn ? field.stringValue : nil)
        }
    }

    @available(macOS 12.0, *)
    func webView(
        _ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType,
        decisionHandler: @escaping (WKPermissionDecision) -> Void
    ) {
        decisionHandler(.grant)
    }

    // MARK: - Descargas (exportar JSON)

    func webView(
        _ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        decisionHandler(navigationAction.shouldPerformDownload ? .download : .allow)
    }

    func webView(
        _ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        decisionHandler(navigationResponse.canShowMIMEType ? .allow : .download)
    }

    func webView(
        _ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload
    ) {
        download.delegate = self
    }

    func webView(
        _ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload
    ) {
        download.delegate = self
    }

    func download(
        _ download: WKDownload, decideDestinationUsing response: URLResponse,
        suggestedFilename: String, completionHandler: @escaping (URL?) -> Void
    ) {
        let downloads =
            FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
        let filename = suggestedFilename.isEmpty ? "transi.json" : suggestedFilename
        var destination = downloads.appendingPathComponent(filename)

        if FileManager.default.fileExists(atPath: destination.path) {
            let base = destination.deletingPathExtension().lastPathComponent
            let ext = destination.pathExtension
            let stamp = Int(Date().timeIntervalSince1970)
            destination = downloads.appendingPathComponent(
                ext.isEmpty ? "\(base)-\(stamp)" : "\(base)-\(stamp).\(ext)")
        }
        completionHandler(destination)
    }

    // MARK: - Menú

    private func buildMenu() {
        let mainMenu = NSMenu()

        let appItem = NSMenuItem()
        mainMenu.addItem(appItem)
        let appMenu = NSMenu()
        appMenu.addItem(
            withTitle: "Acerca de Transi",
            action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(
            withTitle: "Ocultar Transi", action: #selector(NSApplication.hide(_:)),
            keyEquivalent: "h")
        let hideOthers = appMenu.addItem(
            withTitle: "Ocultar otros", action: #selector(NSApplication.hideOtherApplications(_:)),
            keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(
            withTitle: "Mostrar todo", action: #selector(NSApplication.unhideAllApplications(_:)),
            keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(
            withTitle: "Salir de Transi", action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q")
        appItem.submenu = appMenu

        let editItem = NSMenuItem()
        mainMenu.addItem(editItem)
        let editMenu = NSMenu(title: "Editar")
        editMenu.addItem(
            withTitle: "Deshacer", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(
            withTitle: "Rehacer", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(.separator())
        editMenu.addItem(
            withTitle: "Cortar", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(
            withTitle: "Copiar", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(
            withTitle: "Pegar", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(
            withTitle: "Seleccionar todo", action: #selector(NSText.selectAll(_:)),
            keyEquivalent: "a")
        editItem.submenu = editMenu

        let viewItem = NSMenuItem()
        mainMenu.addItem(viewItem)
        let viewMenu = NSMenu(title: "Ver")
        let reload = viewMenu.addItem(
            withTitle: "Recargar", action: #selector(reloadPage), keyEquivalent: "r")
        reload.target = self
        viewMenu.addItem(.separator())
        let fullscreen = viewMenu.addItem(
            withTitle: "Pantalla completa", action: #selector(NSWindow.toggleFullScreen(_:)),
            keyEquivalent: "f")
        fullscreen.keyEquivalentModifierMask = [.command, .control]
        viewItem.submenu = viewMenu

        NSApp.mainMenu = mainMenu
    }

    @objc private func reloadPage() {
        webView?.reload()
    }
}

@main
struct TransiApp {
    static let delegate = AppDelegate()

    static func main() {
        let app = NSApplication.shared
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        app.run()
    }
}
