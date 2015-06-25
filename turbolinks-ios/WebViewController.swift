import UIKit
import WebKit

class WebViewController: UIViewController, WKScriptMessageHandler {
    @IBOutlet var mainView : UIView?

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

    override func loadView() {
        super.loadView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        var URL = NSURL(string: "http://turbolinks.dev/")
        self.webView.loadRequest(NSURLRequest(URL: URL!))
        self.view = webView
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        println("\(message.name): \(message.body)")
    }
}
