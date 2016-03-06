import UIKit
import WebKit

protocol AuthenticationControllerDelegate: class {
    func authenticationControllerDidAuthenticate(authenticationController: AuthenticationController)
}

class AuthenticationController: UIViewController, WKNavigationDelegate {
    var URL: NSURL?
    var webViewConfiguration: WKWebViewConfiguration?
    weak var delegate: AuthenticationControllerDelegate?

    lazy var webView: WKWebView = {
        let configuration = self.webViewConfiguration ?? WKWebViewConfiguration()
        let webView = WKWebView(frame: CGRectZero, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        return webView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(webView)
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: [], metrics: nil, views: [ "view": webView ]))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: [], metrics: nil, views: [ "view": webView ]))

        if let URL = self.URL {
            webView.loadRequest(NSURLRequest(URL: URL))
        }
    }

    // MARK: WKNavigationDelegate

    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        if let URL = navigationAction.request.URL where URL != self.URL {
            decisionHandler(.Cancel)
            delegate?.authenticationControllerDidAuthenticate(self)
            return
        }

        decisionHandler(.Allow)
    }
}
