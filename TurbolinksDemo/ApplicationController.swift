import UIKit
import WebKit
import Turbolinks

class ApplicationController: UINavigationController {
    private let URL = NSURL(string: "http://localhost:9292")!
    private let webViewProcessPool = WKProcessPool()

    private var application: UIApplication {
        return UIApplication.sharedApplication()
    }

    private lazy var webViewConfiguration: WKWebViewConfiguration = {
        let bundle = NSBundle.mainBundle()
        let source = try! String(contentsOfURL: bundle.URLForResource("TurbolinksDemo", withExtension: "js")!, encoding: NSUTF8StringEncoding)
        let userScript = WKUserScript(source: source, injectionTime: .AtDocumentEnd, forMainFrameOnly: true)

        let configuration = WKWebViewConfiguration()
        configuration.userContentController.addUserScript(userScript)
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
        presentVisitableForSession(session, URL: URL)
    }

    private func presentVisitableForSession(session: Session, URL: NSURL, action: Action = .Advance) {
        let visitable = DemoViewController()
        visitable.visitableURL = URL

        if action == .Advance {
            pushViewController(visitable, animated: true)
        } else if action == .Replace {
            popViewControllerAnimated(false)
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
        authenticationController.URL = URL.URLByAppendingPathComponent("sign-in")
        authenticationController.title = "Sign in"

        let authNavigationController = UINavigationController(rootViewController: authenticationController)
        presentViewController(authNavigationController, animated: true, completion: nil)
    }
}

extension ApplicationController: SessionDelegate {
    func session(session: Session, didProposeVisitToURL URL: NSURL, withAction action: Action) {
        if URL.path == "/numbers" {
            presentNumbersViewController()
        } else {
            presentVisitableForSession(session, URL: URL, action: action)
        }
    }
    
    func sessionDidStartRequest(session: Session) {
        application.networkActivityIndicatorVisible = true
    }
    
    func session(session: Session, didFailRequestForVisitable visitable: Visitable, withError error: NSError) {
        print("ERROR: \(error)")
        guard let demoViewController = visitable as? DemoViewController else { return }

        switch error.code {
        case ErrorCode.HTTPFailure.rawValue:
            let statusCode = error.userInfo["statusCode"] as! Int
            switch statusCode {
            case 401:
                presentAuthenticationController()
            case 404:
                demoViewController.presentError(.HTTPNotFoundError)
            default:
                demoViewController.presentError(Error(HTTPStatusCode: statusCode))
            }
        case ErrorCode.NetworkFailure.rawValue:
            demoViewController.presentError(.NetworkError)
        default:
            demoViewController.presentError(.UnknownError)
        }
    }
    
    func sessionDidFinishRequest(session: Session) {
        application.networkActivityIndicatorVisible = false
    }
    
    func sessionDidInitializeWebView(session: Session) {
        session.webView.navigationDelegate = self
    }
}

extension ApplicationController: WKNavigationDelegate {
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> ()) {
        decisionHandler(WKNavigationActionPolicy.Cancel)
        
        if let URL = navigationAction.request.URL {
            UIApplication.sharedApplication().openURL(URL)
        }
    }
}

extension ApplicationController: AuthenticationControllerDelegate {
    func authenticationControllerDidAuthenticate(authenticationController: AuthenticationController) {
        session.reload()
        dismissViewControllerAnimated(true, completion: nil)
    }
}
