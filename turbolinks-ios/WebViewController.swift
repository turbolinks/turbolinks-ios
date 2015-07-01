import UIKit
import WebKit

protocol WebViewControllerNavigationDelegate {
    func visitLocation(URL: NSURL)
    func locationDidChange(URL: NSURL)
}

class WebViewController: UIViewController, WebViewControllerNavigationDelegate {
    class ScriptHandler: NSObject, WKScriptMessageHandler {
        static let instance: ScriptHandler = {
            return ScriptHandler()
        }()

        var delegate: WebViewControllerNavigationDelegate?

        func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
            if let body = message.body as? [String: AnyObject],
                name = body["name"] as? String,
                data = body["data"] as? String {
                    switch name {
                    case "visitLocation":
                        if let location = NSURL(string: data) {
                            delegate?.visitLocation(location)
                        }
                    case "locationChanged":
                        if let location = NSURL(string: data) {
                            delegate?.locationDidChange(location)
                        }
                    default:
                        println("Unhandled message: \(name): \(data)")
                    }
            }
        }
    }

    var URL = NSURL(string: "http://turbolinks.dev/")!
    var activeSessionTask: NSURLSessionTask?

    static let sharedWebView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = WKUserContentController()

        let webView = WKWebView(frame: CGRectZero, configuration: configuration)
        webView.setTranslatesAutoresizingMaskIntoConstraints(false)
        webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal

        let appSource = NSString(contentsOfURL: NSBundle.mainBundle().URLForResource("app", withExtension: "js")!, encoding: NSUTF8StringEncoding, error: nil)!
        webView.configuration.userContentController.addUserScript(WKUserScript(source: appSource as! String, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: true))
        webView.configuration.userContentController.addScriptMessageHandler(ScriptHandler.instance, name: "turbolinks")

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
            let request = NSURLRequest(URL: URL)
            webView.loadRequest(request)
        }
    }

    private func loadRequest(request: NSURLRequest) {
        if let sessionTask = activeSessionTask {
            sessionTask.cancel()
        }
       
        let session = NSURLSession.sharedSession()
        activeSessionTask = session.dataTaskWithRequest(request) { (data, response, error) in
            if let httpResponse = response as? NSHTTPURLResponse
                where httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                    dispatch_async(dispatch_get_main_queue()) {
                        if let response = NSString(data: data, encoding: NSUTF8StringEncoding) as? String {
                            self.loadResponse(response)
                        }
                    }
            }
        }

        activeSessionTask?.resume()
    }

    private func loadResponse(response: String) {
        let webViewController = WebViewController()
        webViewController.URL = URL
        navigationController?.pushViewController(webViewController, animated: true)

        let serializedResponse = JSONStringify(response)
        webView.evaluateJavaScript("Turbolinks.controller.loadResponse(\(serializedResponse))", completionHandler: nil)
    }
    
    // MARK - WebViewControllerNavigationDelegate

    func visitLocation(location: NSURL) {
        let request = NSURLRequest(URL: location)
        loadRequest(request)
    }
    
    func locationDidChange(location: NSURL) {
        
    }
}

func JSONStringify(object: AnyObject) -> String {
    if let data = NSJSONSerialization.dataWithJSONObject([object], options: nil, error: nil),
        string = NSString(data: data, encoding: NSUTF8StringEncoding) as? String {
            return string[Range(start: string.startIndex.successor(), end: string.endIndex.predecessor())]
    } else {
        return "null"
    }
}
