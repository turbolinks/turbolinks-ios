import UIKit
import WebKit
import Turbolinks

class ApplicationController: UINavigationController {
    fileprivate let url = URL(string: "http://localhost:9292")!
    fileprivate let webViewProcessPool = WKProcessPool()

    fileprivate var application: UIApplication {
        return UIApplication.shared
    }

    fileprivate lazy var webViewConfiguration: WKWebViewConfiguration = {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(self, name: "turbolinksDemo")
        configuration.processPool = self.webViewProcessPool
        configuration.applicationNameForUserAgent = "TurbolinksDemo"
        return configuration
    }()

    fileprivate lazy var session: Session = {
        let session = Session(webViewConfiguration: self.webViewConfiguration)
        session.delegate = self
        return session
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        presentVisitableForSession(session, url: url)
    }

    fileprivate func presentVisitableForSession(_ session: Session, url: URL, action: Action = .Advance) {
        let visitable = DemoViewController(url: url)

        if action == .Advance {
            pushViewController(visitable, animated: true)
        } else if action == .Replace {
            popViewController(animated: false)
            pushViewController(visitable, animated: false)
        }
        
        session.visit(visitable)
    }

    fileprivate func presentNumbersViewController() {
        let viewController = NumbersViewController()
        pushViewController(viewController, animated: true)
    }

    fileprivate func presentAuthenticationController() {
        let authenticationController = AuthenticationController()
        authenticationController.delegate = self
        authenticationController.webViewConfiguration = webViewConfiguration
        authenticationController.url = url.appendingPathComponent("sign-in")
        authenticationController.title = "Sign in"

        let authNavigationController = UINavigationController(rootViewController: authenticationController)
        present(authNavigationController, animated: true, completion: nil)
    }
}

extension ApplicationController: SessionDelegate {
    func session(_ session: Session, didProposeVisitToURL URL: Foundation.URL, withAction action: Action) {
        if URL.path == "/numbers" {
            presentNumbersViewController()
        } else {
            presentVisitableForSession(session, url: URL, action: action)
        }
    }
    
    func session(_ session: Session, didFailRequestForVisitable visitable: Visitable, withError error: NSError) {
        NSLog("ERROR: %@", error)
        guard let demoViewController = visitable as? DemoViewController, let errorCode = ErrorCode(rawValue: error.code) else { return }

        switch errorCode {
        case .httpFailure:
            let statusCode = error.userInfo["statusCode"] as! Int
            switch statusCode {
            case 401:
                presentAuthenticationController()
            case 404:
                demoViewController.presentError(.HTTPNotFoundError)
            default:
                demoViewController.presentError(Error(HTTPStatusCode: statusCode))
            }
        case .networkFailure:
            demoViewController.presentError(.NetworkError)
        }
    }
    
    func sessionDidStartRequest(_ session: Session) {
        application.isNetworkActivityIndicatorVisible = true
    }

    func sessionDidFinishRequest(_ session: Session) {
        application.isNetworkActivityIndicatorVisible = false
    }
}

extension ApplicationController: AuthenticationControllerDelegate {
    func authenticationControllerDidAuthenticate(_ authenticationController: AuthenticationController) {
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
