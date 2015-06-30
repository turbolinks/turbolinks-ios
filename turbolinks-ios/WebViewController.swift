import UIKit
import WebKit

protocol WebViewControllerNavigationDelegate {
    func pageWillChange(URL: NSURL!)
}

class WebViewController: UIViewController, WebViewControllerNavigationDelegate {
    class ScriptHandler: NSObject, WKScriptMessageHandler {
        static let instance: ScriptHandler = {
            return ScriptHandler()
        }()

        var delegate: WebViewControllerNavigationDelegate?

        func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
            if let body = message.body as? [String: AnyObject] {
                var name = body["name"] as? String
                var data = body["data"] as? String

                switch name! {
                case "page:before-change":
                    self.delegate?.pageWillChange(NSURL(string: data!))
                case "log":
                    println(data)
                default:
                    println("Unhandled message: \(name): \(data)")
                }
            }
        }
    }

    var URL = NSURL(string: "http://turbolinks.dev/")

    static let sharedWebView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = WKUserContentController()

        let webView = WKWebView(frame: CGRectZero, configuration: configuration)
        webView.setTranslatesAutoresizingMaskIntoConstraints(false)
        webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal

        let appSource = NSString(contentsOfURL: NSBundle.mainBundle().URLForResource("app", withExtension: "js")!, encoding: NSUTF8StringEncoding, error: nil)!
        webView.configuration.userContentController.addUserScript(WKUserScript(source: appSource as! String, injectionTime: WKUserScriptInjectionTime.AtDocumentStart, forMainFrameOnly: true))
        webView.configuration.userContentController.addScriptMessageHandler(ScriptHandler.instance, name: "bridgeMessage")

        return webView
    }()

    lazy var webView: WKWebView = {
        return WebViewController.sharedWebView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        edgesForExtendedLayout = .None
        automaticallyAdjustsScrollViewInsets = false
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        prepareScriptHandler()
        insertWebView()
        loadRequest()
    }

    private func prepareScriptHandler() {
        ScriptHandler.instance.delegate = self
    }

    private func insertWebView() {
        view.addSubview(webView)
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: nil, metrics: nil, views: [ "view": webView ]))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: nil, metrics: nil, views: [ "view": webView ]))
    }

    private func loadRequest() {
        if webView.URL == nil {
            webView.loadRequest(NSURLRequest(URL: URL!))
        } else {
            loadRequestWithTurbolinks()
        }
    }

    private func loadRequestWithTurbolinks() {
        webView.evaluateJavaScript("Turbolinks.visit('\(URL!.absoluteString!)')", completionHandler: nil)
    }

    // MARK - WebViewControllerNavigationDelegate

    func pageWillChange(URL: NSURL!) {
        let webViewController = WebViewController()
        webViewController.URL = URL
        navigationController?.pushViewController(webViewController, animated: true)
    }
}
