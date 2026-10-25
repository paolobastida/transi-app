import Foundation
import Network

/// Sirve el bundle local por loopback para que WKWebView pueda cargar módulos,
/// cámara y micrófono con un origen local estable.
final class LocalHTTPServer {
    enum ServerError: Error {
        case couldNotStart
    }

    private static let puertoPreferido: UInt16 = 47616
    private let root: URL
    private let queue = DispatchQueue(label: "com.transi.ios-local-server")
    private var listener: NWListener?
    private(set) var port: UInt16 = 0

    init(root: URL) {
        self.root = root
    }

    func start() throws {
        guard let port = NWEndpoint.Port(rawValue: Self.puertoPreferido) else {
            throw ServerError.couldNotStart
        }
        let parameters = NWParameters.tcp
        parameters.requiredLocalEndpoint = .hostPort(host: "127.0.0.1", port: port)
        let listener = try NWListener(using: parameters)
        self.listener = listener

        let ready = DispatchSemaphore(value: 0)
        var didStart = false
        listener.stateUpdateHandler = { state in
            switch state {
            case .ready:
                didStart = true
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

        guard ready.wait(timeout: .now() + 5) == .success, didStart else {
            listener.cancel()
            throw ServerError.couldNotStart
        }
        self.port = Self.puertoPreferido
    }

    private func accept(_ connection: NWConnection) {
        if case let .hostPort(host, _) = connection.endpoint {
            let address = "\(host)"
            guard address == "127.0.0.1" || address == "::1"
                    || address == "::ffff:127.0.0.1" else {
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
            if let data { buffer.append(data) }
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
        if let query = path.firstIndex(of: "?") { path = String(path[..<query]) }
        path = path.removingPercentEncoding ?? path
        if path.isEmpty || path == "/" { path = "/index.html" }

        let segments = path.split(separator: "/").map(String.init).filter {
            $0 != "." && $0 != ".."
        }
        let file = root.appendingPathComponent(segments.joined(separator: "/"))
        let content = (try? Data(contentsOf: file)) ?? Data()
        let found = !content.isEmpty
        let body = found ? content : Data("No encontrado".utf8)
        let mime = found ? Self.mimeType(file.pathExtension) : "text/plain; charset=utf-8"
        let status = found ? "200 OK" : "404 Not Found"
        let headers = "HTTP/1.1 \(status)\r\nContent-Type: \(mime)\r\n"
            + "Content-Length: \(body.count)\r\nCache-Control: no-cache\r\n"
            + "Connection: close\r\n\r\n"
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
        case "json": return "application/json"
        case "webmanifest": return "application/manifest+json"
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
