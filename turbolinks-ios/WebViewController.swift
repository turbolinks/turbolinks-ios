import UIKit
import WebKit

protocol WebViewControllerNavigationDelegate: class {
    func visitLocation(URL: NSURL)
    func locationDidChange(URL: NSURL)
}

class ScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: WebViewControllerNavigationDelegate?
    
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

class WebViewController: UIViewController, WebViewControllerNavigationDelegate {
    static let scriptMessageHandler = ScriptMessageHandler()
    static let sharedWebView = WebViewController.createWebView(scriptMessageHandler)

    var URL = NSURL(string: "http://bc3.dev/195539477/")!
    var activeSessionTask: NSURLSessionTask?
    let webView = WebViewController.sharedWebView

    class func createWebView(scriptMessageHandler: WKScriptMessageHandler) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = WKUserContentController()

        let webView = WKWebView(frame: CGRectZero, configuration: configuration)
        webView.setTranslatesAutoresizingMaskIntoConstraints(false)
        webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal

        let appSource = NSString(contentsOfURL: NSBundle.mainBundle().URLForResource("app", withExtension: "js")!, encoding: NSUTF8StringEncoding, error: nil)!
        webView.configuration.userContentController.addUserScript(WKUserScript(source: appSource as! String, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: true))
        webView.configuration.userContentController.addScriptMessageHandler(scriptMessageHandler, name: "turbolinks")

        return webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        edgesForExtendedLayout = .None
        automaticallyAdjustsScrollViewInsets = false
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        prepareScriptMessageHandler()
        insertWebView()
        performRequest()
    }

    private func prepareScriptMessageHandler() {
        WebViewController.scriptMessageHandler.delegate = self
    }

    private func insertWebView() {
        view.addSubview(webView)
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: nil, metrics: nil, views: [ "view": webView ]))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: nil, metrics: nil, views: [ "view": webView ]))
    }

    private func performRequest() {
        let request = NSURLRequest(URL: URL)

        if webView.URL == nil {
            webView.loadRequest(request)
        } else {
            // This isn't the right time to call navigateToLocation. We should wait to call it until we know it's the final destination, on viewDidAppear. We should also make sure to only call loadResponse on or after viewDidAppear.
            navigateToLocation(URL)
            loadRequest(request)
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
        let serializedResponse = JSONStringify(response)
        webView.evaluateJavaScript("Turbolinks.controller.loadResponse(\(serializedResponse))", completionHandler: nil)
    }
    
    private func navigateToLocation(location: NSURL) {
        let serializedURL = JSONStringify("\(location)")
        webView.evaluateJavaScript("Turbolinks.controller.history.push(\(serializedURL))", completionHandler: nil)
    }
    
    // MARK - WebViewControllerNavigationDelegate

    func visitLocation(location: NSURL) {
        let webViewController = WebViewController()
        webViewController.URL = location
        navigationController?.pushViewController(webViewController, animated: true)
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
