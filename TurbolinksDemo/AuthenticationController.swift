import UIKit
import WebKit

protocol AuthenticationControllerDelegate: class {
    func authenticationControllerDidAuthenticate(_ authenticationController: AuthenticationController)
}

class AuthenticationController: UIViewController {
    var url: URL?
    var webViewConfiguration: WKWebViewConfiguration?
    weak var delegate: AuthenticationControllerDelegate?

    lazy var webView: WKWebView = {
        let configuration = self.webViewConfiguration ?? WKWebViewConfiguration()
        let webView = WKWebView(frame: CGRect.zero, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        return webView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(webView)
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: [], metrics: nil, views: [ "view": webView ]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: [], metrics: nil, views: [ "view": webView ]))

        if let url = self.url {
            webView.load(URLRequest(url: url))
        }
    }
}

extension AuthenticationController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url, url != self.url {
            decisionHandler(.cancel)
            delegate?.authenticationControllerDidAuthenticate(self)
            return
        }

        decisionHandler(.allow)
    }
}
