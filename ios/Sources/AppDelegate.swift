import UIKit
import WebKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate, WKUIDelegate {
    var window: UIWindow?
    private var recordatorios: Recordatorios?
    private var servidor: LocalHTTPServer?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        guard let carpetaDist = Bundle.main.resourceURL?.appendingPathComponent("dist") else {
            assertionFailure("No se encontró la app web incluida en el bundle.")
            return false
        }

        let servidor = LocalHTTPServer(root: carpetaDist)
        do {
            try servidor.start()
        } catch {
            assertionFailure("No se pudo iniciar el servidor local de Transi: \(error)")
            return false
        }
        self.servidor = servidor

        let configuracion = WKWebViewConfiguration()
        configuracion.allowsInlineMediaPlayback = true
        configuracion.mediaTypesRequiringUserActionForPlayback = []

        let servicioRecordatorios = Recordatorios()
        configuracion.userContentController.add(
            servicioRecordatorios, name: Recordatorios.nombreMensaje)
        recordatorios = servicioRecordatorios

        let webView = WKWebView(frame: .zero, configuration: configuracion)
        webView.uiDelegate = self
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        servicioRecordatorios.conectar(webView)

        let controlador = UIViewController()
        controlador.view.backgroundColor = UIColor(red: 0.969, green: 0.984, blue: 0.992, alpha: 1)
        controlador.view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: controlador.view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: controlador.view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: controlador.view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: controlador.view.bottomAnchor),
        ])

        let ventana = UIWindow(frame: UIScreen.main.bounds)
        ventana.rootViewController = controlador
        ventana.makeKeyAndVisible()
        window = ventana

        webView.load(URLRequest(url: URL(string: "http://127.0.0.1:\(servidor.port)/")!))
        return true
    }

    @available(iOS 15.0, *)
    func webView(
        _ webView: WKWebView,
        requestMediaCapturePermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        type: WKMediaCaptureType,
        decisionHandler: @escaping (WKPermissionDecision) -> Void
    ) {
        // WebKit muestra y gestiona el permiso del sistema para la cámara o el micrófono.
        decisionHandler(.grant)
    }
}
