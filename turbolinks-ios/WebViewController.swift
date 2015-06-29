import UIKit
import WebKit

class WebViewController: UIViewController, WKScriptMessageHandler {
    var URL = NSURL(string: "http://turbolinks.dev/")

    lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = WKUserContentController()

        let webView = WKWebView(frame: CGRectZero, configuration: configuration)
        webView.setTranslatesAutoresizingMaskIntoConstraints(false)
        webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal
        webView.configuration.userContentController.addScriptMessageHandler(self, name: "bridgeMessage")

        let appSource = NSString(contentsOfURL: NSBundle.mainBundle().URLForResource("app", withExtension: "js")!, encoding: NSUTF8StringEncoding, error: nil)!
        webView.configuration.userContentController.addUserScript(WKUserScript(source: appSource as! String, injectionTime: WKUserScriptInjectionTime.AtDocumentStart, forMainFrameOnly: true))

        return webView
    }()

    init(URL: NSURL) {
        super.init(nibName: nil, bundle: nil)
        self.URL = URL
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func loadView() {
        self.view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.webView.loadRequest(NSURLRequest(URL: self.URL!))
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        println("\(message.name): \(message.body)")

        if let body = message.body as? [String: AnyObject] {
            if body["name"] as? String == "page:before-change" {
                let webViewController = WebViewController(URL: NSURL(string: body["data"] as! String)!)
                self.navigationController?.pushViewController(webViewController, animated: true)
            }
        }
    }
}
