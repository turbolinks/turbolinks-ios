import UIKit
import WebKit

protocol VisitableDelegate: class {
    func visitableWebViewWillDisappear(visitable: Visitable)
    func visitableWebViewDidDisappear(visitable: Visitable)
    func visitableWebViewWillAppear(visitable: Visitable)
    func visitableWebViewDidAppear(visitable: Visitable)
}

protocol Visitable {
    weak var visitableDelegate: VisitableDelegate? { get set }
    var hasScreenshot: Bool { get }
    var location: NSURL? { get set }
    var viewController: UIViewController { get }

    func activateWebView(webView: WKWebView)
    func deactivateWebView()
    func showLoadingIndicator()
    func hideLoadingIndicator()
    func updateScreenshot()
    func showScreenshot()
    func hideScreenshot()
}

protocol SessionDelegate: class {
    func prepareWebViewConfiguration(configuration: WKWebViewConfiguration, forSession session: Session)
    func visitableForSession(session: Session, location: NSURL) -> Visitable
}

class Session: NSObject, WKNavigationDelegate, WKScriptMessageHandler, VisitableDelegate {
    weak var delegate: SessionDelegate?
    var navigationController: UINavigationController?
    var location: NSURL?
    var activeSessionTask: NSURLSessionTask?
    var visiting: Bool = false
    var initialized: Bool = false
    var activeVisitable: Visitable?

    lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = WKUserContentController()

        let userScript = NSString(contentsOfURL: NSBundle.mainBundle().URLForResource("app", withExtension: "js")!, encoding: NSUTF8StringEncoding, error: nil)!
        configuration.userContentController.addUserScript(WKUserScript(source: userScript as! String, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: true))
        configuration.userContentController.addScriptMessageHandler(self, name: "turbolinks")

        self.delegate?.prepareWebViewConfiguration(configuration, forSession: self)

        let webView = WKWebView(frame: CGRectZero, configuration: configuration)
        webView.setTranslatesAutoresizingMaskIntoConstraints(false)
        webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal
        webView.navigationDelegate = self

        return webView
    }()

    // MARK: WKNavigationDelegate
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        self.initialized = true
    }
   
    // MARK: WKScriptMessageHandler

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if let body = message.body as? [String: AnyObject],
            name = body["name"] as? String,
            data = body["data"] as? String {
                switch name {
                case "visit":
                    if let location = NSURL(string: data) {
                        visit(location)
                    }
                case "locationChanged":
                    if let location = NSURL(string: data) {
                        locationChanged(location)
                    }
                default:
                    println("Unhandled message: \(name): \(data)")
                }
        }
    }

    func visit(location: NSURL) {
        self.visiting = true
        self.location = location

        if let visitable = delegate?.visitableForSession(self, location: location) {
            pushVisitable(visitable)
            issueRequestForURL(location)
        }
    }

    private func locationChanged(location: NSURL) {
        // execute callbacks
        println("locationChanged: \(location)")
    }
    
    private func pushVisitable(visitable: Visitable) {
        if let navigationController = self.navigationController {
            visitable.activateWebView(webView)
            navigationController.pushViewController(visitable.viewController, animated: true)
        }
    }

    // MARK: VisitableDelegate

    func visitableWebViewWillDisappear(visitable: Visitable) {
        visitable.updateScreenshot()
    }

    func visitableWebViewDidDisappear(visitable: Visitable) {
        visitable.deactivateWebView()
    }

    func visitableWebViewWillAppear(visitable: Visitable) {
        if !visiting && activeVisitable != nil {
            willNavigateBackwardToVisitable(visitable)
        }
    }

    func visitableWebViewDidAppear(visitable: Visitable) {
        self.activeVisitable = visitable
        visitable.activateWebView(webView)
        if let location = visitable.location {
            pushLocation(location)
        }
    }

    private func pushLocation(location: NSURL) {
        let locationJSON = JSONStringify(location.absoluteString!)
        webView.evaluateJavaScript("Turbolinks.controller.history.push(\(locationJSON))", completionHandler: nil)
    }

    private func willNavigateBackwardToVisitable(visitable: Visitable) {
        if let URL = visitable.location {
            let request = NSURLRequest(URL: URL)
            loadRequest(request)
        }
    }

    // MARK: Request/Response Cycle

    private func issueRequestForURL(location: NSURL) {
        let request = NSURLRequest(URL: location)

        if webView.URL == nil {
            webView.loadRequest(request)
        } else {
            loadRequest(request)
        }
    }
    
    private func loadRequest(request: NSURLRequest) {
        activeSessionTask?.cancel()
        
        let session = NSURLSession.sharedSession()
        activeSessionTask = session.dataTaskWithRequest(request) { (data, response, error) in
            if let httpResponse = response as? NSHTTPURLResponse
                where httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                    if let response = NSString(data: data, encoding: NSUTF8StringEncoding) as? String {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.loadResponse(response)
                            self.visiting = false
                        }
                    }
            }
        }

        activeSessionTask?.resume()
    }

    private func loadResponse(response: String) {
        let responseJSON = JSONStringify(response)
        webView.evaluateJavaScript("Turbolinks.controller.loadResponse(\(responseJSON))", completionHandler: nil)
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
