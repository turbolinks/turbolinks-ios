import UIKit
import WebKit

public protocol TLSessionDelegate: class {
    func prepareWebViewConfiguration(configuration: WKWebViewConfiguration, forSession session: TLSession)
    func presentVisitable(visitable: TLVisitable, forSession session: TLSession)
    func visitableForLocation(location: NSURL, session: TLSession) -> TLVisitable
    func requestForLocation(location: NSURL) -> NSURLRequest
    func sessionWillIssueRequest(session: TLSession)
    func sessionDidFinishRequest(session: TLSession)
    func session(session: TLSession, didInitializeWebView webView: WKWebView)
}

public class TLSession: NSObject, WKScriptMessageHandler, TLVisitDelegate, TLVisitableDelegate {
    public weak var delegate: TLSessionDelegate?

    var initialized: Bool = false
    var location: NSURL?

    var activeVisitable: TLVisitable?
    var activeVisitCompleted = false

    lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = WKUserContentController()

        let bundle = NSBundle(forClass: self.dynamicType)
        let userScript = String(contentsOfURL: bundle.URLForResource("NativeAdapter", withExtension: "js")!, encoding: NSUTF8StringEncoding, error: nil)!
        configuration.userContentController.addUserScript(WKUserScript(source: userScript, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: true))
        configuration.userContentController.addScriptMessageHandler(self, name: "turbolinks")

        self.delegate?.prepareWebViewConfiguration(configuration, forSession: self)

        let webView = WKWebView(frame: CGRectZero, configuration: configuration)
        webView.setTranslatesAutoresizingMaskIntoConstraints(false)
        webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal

        return webView
    }()
    
    // MARK: Visiting

    private var visit: TLVisit?
    
    public func visit(location: NSURL) {
        if let visitable = delegate?.visitableForLocation(location, session: self) {
            if presentVisitable(visitable) {
                issueVisitForVisitable(visitable)
            }
        }
    }
    
    private func presentVisitable(visitable: TLVisitable) -> Bool {
        if let delegate = self.delegate {
            delegate.presentVisitable(visitable, forSession: self)
            return true
        } else {
            return false
        }
    }
    
    private func issueVisitForVisitable(visitable: TLVisitable) {
        if let location = visitable.location {
            let visit: TLVisit
            let request = requestForLocation(location)
            
            if initialized {
                visit = TLTurbolinksVisit(visitable: visitable, request: request)
            } else {
                visit = TLWebViewVisit(visitable: visitable, request: request, webView: webView)
            }
            
            self.visit?.cancel()
            self.visit = visit

            visit.delegate = self
            visit.startRequest()
        }
    }
    
    private func requestForLocation(location: NSURL) -> NSURLRequest {
        return delegate?.requestForLocation(location) ?? NSURLRequest(URL: location)
    }
    
    // MARK: WKScriptMessageHandler

    public func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if let body = message.body as? [String: AnyObject],
            name = body["name"] as? String {
                switch name {
                case "visit":
                    if let data = body["data"] as? String, location = NSURL(string: data) {
                        visit(location)
                    }
                case "locationChanged":
                    if let data = body["data"] as? String, location = NSURL(string: data) {
                        locationChanged(location)
                    }
                case "webViewRendered":
                    webViewRendered()
                default:
                    println("Unhandled message: \(name)")
                }
        }
    }

    private func locationChanged(location: NSURL) {
        if let visit = self.visit {
            visit.completeNavigation()
        }
    }
    
    private func webViewRendered() {
        visit?.finish()
    }
    
    // MARK: VisitDelegate
    
    func visitWillIssueRequest(visit: TLVisit) {
        delegate?.sessionWillIssueRequest(self)
    }
    
    func visitDidFinishRequest(visit: TLVisit) {
        delegate?.sessionDidFinishRequest(self)
    }

    func visit(visit: TLVisit, didCompleteWithResponse response: String) {
        loadResponse(response)
        self.activeVisitCompleted = true
    }
    
    func visitDidCompleteWebViewLoad(visit: TLVisit) {
        self.initialized = true
        delegate?.session(self, didInitializeWebView: webView)
        self.activeVisitCompleted = true
    }
   
    func visitDidStart(visit: TLVisit) {
        let visitable = visit.visitable
        visitable.showScreenshot()
        visitable.showActivityIndicator()
    }
    
    func visitDidFinish(visit: TLVisit) {
        let visitable = visit.visitable

        if activeVisitCompleted {
            visitable.hideScreenshot()
            visitable.hideActivityIndicator()
        }

        self.visit = nil
    }
   
    private func loadResponse(response: String) {
        invokeJavaScriptMethod("Turbolinks.controller.loadResponse", withArguments: [response]) { (result, error) -> () in
            self.invokeJavaScriptMethod("Turbolinks.controller.adapter.notifyOfNextRender")
        }
    }

    // MARK: VisitableDelegate

    public func visitableViewWillDisappear(visitable: TLVisitable) {
        visitable.updateScreenshot()
    }

    public func visitableViewWillAppear(visitable: TLVisitable) {
        if let activeVisitable = self.activeVisitable {
            if activeVisitable === visitable {
                // Back swipe gesture canceled
                if activeVisitCompleted {
                    // Top visitable was fully loaded before the gesture began
                    visit?.cancel()
                } else {
                    // Top visitable was *not* fully loaded before the gesture began
                    issueVisitForVisitable(visitable)
                }
            } else if visit?.visitable !== visitable {
                // Navigating backward
                issueVisitForVisitable(visitable)
            }
        }
    }
    
    public func visitableViewDidDisappear(visitable: TLVisitable) {
        deactivateVisitable(visitable)
    }

    public func visitableViewDidAppear(visitable: TLVisitable) {
        if let location = visitable.location {
            activateVisitable(visitable)
            pushLocation(location)
        }
    }

    private func activateVisitable(visitable: TLVisitable) {
        self.activeVisitable = visitable
        self.activeVisitCompleted = false
        visitable.activateWebView(webView)
    }
    
    private func deactivateVisitable(visitable: TLVisitable) {
        visitable.deactivateWebView()
    }
    
    private func pushLocation(location: NSURL) {
        invokeJavaScriptMethod("Turbolinks.controller.history.push", withArguments: [location.absoluteString!])
    }
    
    // MARK: JavaScript Evaluation

    private func invokeJavaScriptMethod(methodName: String, withArguments arguments: [AnyObject] = [], completionHandler: ((AnyObject?, NSError?) -> ())? = { (_, _) -> () in }) {
        let script = scriptForInvokingJavaScriptMethod(methodName, withArguments: arguments)
        webView.evaluateJavaScript(script, completionHandler: completionHandler)
    }

    private func scriptForInvokingJavaScriptMethod(methodName: String, withArguments arguments: [AnyObject]) -> String {
        return methodName + "(" + ", ".join(arguments.map(JSONStringify)) + ")"
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

func after(msec: Int, callback: () -> ()) {
    let time = dispatch_time(DISPATCH_TIME_NOW, (Int64)(100 * NSEC_PER_MSEC))
    dispatch_after(time, dispatch_get_main_queue(), callback)
}
