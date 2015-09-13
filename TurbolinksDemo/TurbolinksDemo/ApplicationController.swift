import UIKit
import WebKit
import Turbolinks

class ApplicationController: UIViewController, WKNavigationDelegate, TLSessionDelegate, AuthenticationControllerDelegate {
    let accountLocation = NSURL(string: "http://bc3.dev/195539477/")!
    let webViewProcessPool = WKProcessPool()
    var mainNavigationController: UINavigationController?

    var application: UIApplication {
        return UIApplication.sharedApplication()
    }

    lazy var session: TLSession = {
        let session = TLSession()
        session.delegate = self
        return session
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        installMainNavigationController()
        presentVisitableForSession(session, atLocation: accountLocation)
    }

    func installMainNavigationController() {
        let mainNavigationController = UINavigationController()
        self.mainNavigationController = mainNavigationController
        addChildViewController(mainNavigationController)
        view.addSubview(mainNavigationController.view)
        mainNavigationController.didMoveToParentViewController(self)
    }

    private func presentVisitableForSession(session: TLSession, atLocation location: NSURL) {
        let visitable = visitableForSession(session, atLocation: location)
        mainNavigationController?.pushViewController(visitable.viewController, animated: true)
        session.visit(visitable)
    }

    private func visitableForSession(session: TLSession, atLocation location: NSURL) -> TLVisitable {
        let visitable = WebViewController()
        visitable.location = location
        visitable.visitableDelegate = session
        return visitable
    }

    func presentAuthenticationController() {
        let authenticationController = AuthenticationController()
        authenticationController.accountLocation = accountLocation
        authenticationController.delegate = self
        authenticationController.title = "Sign in"

        let authNavigationController = UINavigationController(rootViewController: authenticationController)
        presentViewController(authNavigationController, animated: true, completion: nil)
    }

    // MARK: TLSessionDelegate

    func prepareWebViewConfiguration(configuration: WKWebViewConfiguration, forSession session: TLSession) {
        let bundle = NSBundle.mainBundle()
        let source = try! String(contentsOfURL: bundle.URLForResource("TurbolinksDemo", withExtension: "js")!, encoding: NSUTF8StringEncoding)
        let userScript = WKUserScript(source: source, injectionTime: .AtDocumentEnd, forMainFrameOnly: true)
        configuration.userContentController.addUserScript(userScript)
        configuration.processPool = webViewProcessPool
    }

    func session(session: TLSession, didProposeVisitToLocation location: NSURL) {
        presentVisitableForSession(session, atLocation: location)
    }

    func sessionDidStartRequest(session: TLSession) {
        application.networkActivityIndicatorVisible = true
    }

    func session(session: TLSession, didFailRequestForVisitable visitable: TLVisitable, withError error: NSError) {
        print("REQUEST ERROR: \(error)")
    }

    func session(session: TLSession, didFailRequestForVisitable visitable: TLVisitable, withStatusCode statusCode: Int) {
        print("RECEIVED ERROR RESPONSE: \(statusCode)")

        if statusCode == 401 {
            presentAuthenticationController()
        }
    }

    func sessionDidFinishRequest(session: TLSession) {
        application.networkActivityIndicatorVisible = false
    }

    func session(session: TLSession, didInitializeWebView webView: WKWebView) {
        webView.navigationDelegate = self
    }

    // MARK: AuthenticationControllerDelegate

    func prepareWebViewConfiguration(configuration: WKWebViewConfiguration, forAuthenticationController authenticationController: AuthenticationController) {
        configuration.processPool = webViewProcessPool
    }

    func authenticationControllerDidAuthenticate(authenticationController: AuthenticationController) {
        session.reload()
        dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: WKNavigationDelegate

    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> ()) {
        decisionHandler(WKNavigationActionPolicy.Cancel)
    }
}
