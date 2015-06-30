import UIKit
import WebKit

protocol WebViewControllerNavigationDelegate {
    func pageWillChange(URL: NSURL!)
}

class ScriptMessageHandler: NSObject, WKScriptMessageHandler {
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

class WebViewPool {
    var members = [ WKWebView ]()
    var currentIndex = 0

    init(scriptMessageHandler: WKScriptMessageHandler) {
        self.members.append(createWebView(scriptMessageHandler))
        self.members.append(createWebView(scriptMessageHandler))
    }

    func next() -> WKWebView {
        if currentIndex == members.count - 1 {
            currentIndex = 0
        } else {
            currentIndex += 1
        }

        return members[currentIndex]
    }

    private func createWebView(scriptMessageHandler: WKScriptMessageHandler) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = WKUserContentController()

        let webView = WKWebView(frame: CGRectZero, configuration: configuration)
        webView.setTranslatesAutoresizingMaskIntoConstraints(false)
        webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal

        let appSource = NSString(contentsOfURL: NSBundle.mainBundle().URLForResource("app", withExtension: "js")!, encoding: NSUTF8StringEncoding, error: nil)!
        webView.configuration.userContentController.addUserScript(WKUserScript(source: appSource as! String, injectionTime: WKUserScriptInjectionTime.AtDocumentStart, forMainFrameOnly: true))
        webView.configuration.userContentController.addScriptMessageHandler(scriptMessageHandler, name: "bridgeMessage")

        return webView
    }
}

class WebViewController: UIViewController, WebViewControllerNavigationDelegate {
    var URL = NSURL(string: "http://turbolinks.dev/")

    static let scriptMessageHandler = ScriptMessageHandler()
    static let webViewPool = WebViewPool(scriptMessageHandler: scriptMessageHandler)

    lazy var webView: WKWebView = {
        return WebViewController.webViewPool.next()
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        edgesForExtendedLayout = .None
        automaticallyAdjustsScrollViewInsets = false
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        prepareScriptMessageHandler()
        insertWebView()
        loadRequest()
    }

    private func prepareScriptMessageHandler() {
        WebViewController.scriptMessageHandler.delegate = self
    }

    private func insertWebView() {
        self.webView = WebViewController.webViewPool.next()
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
