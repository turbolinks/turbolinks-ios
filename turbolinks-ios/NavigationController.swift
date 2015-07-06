import UIKit
import WebKit

class NavigationController: UINavigationController, WKNavigationDelegate, WKScriptMessageHandler {
    let rootURL = NSURL(string: "http://bc3.dev/195539477/")!

    lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = WKUserContentController()

        let webView = WKWebView(frame: CGRectZero, configuration: configuration)
        webView.setTranslatesAutoresizingMaskIntoConstraints(false)
        webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal

        let appSource = NSString(contentsOfURL: NSBundle.mainBundle().URLForResource("app", withExtension: "js")!, encoding: NSUTF8StringEncoding, error: nil)!
        webView.configuration.userContentController.addUserScript(WKUserScript(source: appSource as! String, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: true))
        webView.configuration.userContentController.addScriptMessageHandler(self, name: "turbolinks")

        webView.navigationDelegate = self

        return webView
    }()

    // MARK: WKScriptMessageHandler

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if let body = message.body as? [String: AnyObject],
            name = body["name"] as? String,
            data = body["data"] as? String {
                switch name {
                case "visitLocation":
                    if let location = NSURL(string: data) {
                        visitLocation(location)
                    }
                case "locationChanged":
                    if let location = NSURL(string: data) {
                        locationDidChange(location)
                    }
                default:
                    println("Unhandled message: \(name): \(data)")
                }
        }
    }

    func visitLocation(location: NSURL) {
        let webViewController = WebViewController(URL: location)
        pushViewController(webViewController, animated: true)
    }

    func locationDidChange(location: NSURL) {
    }

    // MARK: WKNavigationDelegate

    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        if let webViewController = topViewController as? WebViewController {
            webViewController.responseDidLoad()
        }
    }
}
