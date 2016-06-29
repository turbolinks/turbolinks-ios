import UIKit
import WebKit
import Turbolinks

class ApplicationController: UINavigationController {
    private let url = URL(string: "http://localhost:9292")!
    private let webViewProcessPool = WKProcessPool()

    private var application: UIApplication {
        return UIApplication.shared()
    }

    private lazy var webViewConfiguration: WKWebViewConfiguration = {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(self, name: "turbolinksDemo")
        configuration.processPool = self.webViewProcessPool
        configuration.applicationNameForUserAgent = "TurbolinksDemo"
        return configuration
    }()

    private lazy var session: Session = {
        let session = Session(webViewConfiguration: self.webViewConfiguration)
        session.delegate = self
        return session
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        presentVisitableForSession(session: session, url: url)
    }

    private func presentVisitableForSession(session: Session, url: URL, action: Action = .Advance) {
        let visitable = DemoViewController(url: url)

        if action == .Advance {
            pushViewController(visitable, animated: true)
        } else if action == .Replace {
            popViewController(animated: false)
            pushViewController(visitable, animated: false)
        }
        
        session.visit(visitable)
    }

    private func presentNumbersViewController() {
        let viewController = NumbersViewController()
        pushViewController(viewController, animated: true)
    }

    private func presentAuthenticationController() {
        let authenticationController = AuthenticationController()
        authenticationController.delegate = self
        authenticationController.webViewConfiguration = webViewConfiguration
        authenticationController.url = try? url.appendingPathComponent("sign-in")
        authenticationController.title = "Sign in"

        let authNavigationController = UINavigationController(rootViewController: authenticationController)
        present(authNavigationController, animated: true, completion: nil)
    }
}

extension ApplicationController: SessionDelegate {
    func session(_ session: Session, didProposeVisitToURL url: URL, withAction action: Action) {
        if url.path == "/numbers" {
            presentNumbersViewController()
        } else {
            presentVisitableForSession(session: session, url: url, action: action)
        }
    }

    func session(_ session: Session, didFailRequestForVisitable visitable: Visitable, withError error: NSError) {
        NSLog("ERROR: %@", error)
        guard let demoViewController = visitable as? DemoViewController, errorCode = ErrorCode(rawValue: error.code) else { return }

        switch errorCode {
        case .httpFailure:
            let statusCode = error.userInfo["statusCode"] as! Int
            switch statusCode {
            case 401:
                presentAuthenticationController()
            case 404:
                demoViewController.presentError(error: .HTTPNotFoundError)
            default:
                demoViewController.presentError(error: Error(HTTPStatusCode: statusCode))
            }
        case .networkFailure:
            demoViewController.presentError(error: .NetworkError)
        }
    }
    
    func sessionDidStartRequest(session: Session) {
        application.isNetworkActivityIndicatorVisible = true
    }

    func sessionDidFinishRequest(session: Session) {
        application.isNetworkActivityIndicatorVisible = false
    }
}

extension ApplicationController: AuthenticationControllerDelegate {
    func authenticationControllerDidAuthenticate(authenticationController: AuthenticationController) {
        session.reload()
        dismiss(animated: true, completion: nil)
    }
}

extension ApplicationController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let message = message.body as? String {
            let alertController = UIAlertController(title: "Turbolinks", message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alertController, animated: true, completion: nil)
        }
    }
}
