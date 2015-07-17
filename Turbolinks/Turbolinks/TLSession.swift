import UIKit
import WebKit

public protocol TLSessionDelegate: class {
    func prepareWebViewConfiguration(configuration: WKWebViewConfiguration, forSession session: TLSession)
    func presentVisitable(visitable: TLVisitable, forSession session: TLSession)

    func visitableForSession(session: TLSession, atLocation location: NSURL) -> TLVisitable
    func requestForSession(session: TLSession, atLocation location: NSURL) -> NSURLRequest

    func sessionWillIssueRequest(session: TLSession)
    func session(session: TLSession, didFailRequestForVisitable visitable: TLVisitable, withError error: NSError)
    func session(session: TLSession, didFailRequestForVisitable visitable: TLVisitable, withStatusCode statusCode: Int)
    func sessionDidFinishRequest(session: TLSession)
    func session(session: TLSession, didInitializeWebView webView: WKWebView)
}

public class TLSession: NSObject, WKScriptMessageHandler, TLVisitDelegate, TLVisitableDelegate {
    public weak var delegate: TLSessionDelegate?

    var initialized: Bool = false
    var refreshing: Bool = false

    var currentVisitable: TLVisitable?

    lazy var webView: TLWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = WKUserContentController()

        let bundle = NSBundle(forClass: self.dynamicType)
        let userScript = String(contentsOfURL: bundle.URLForResource("NativeAdapter", withExtension: "js")!, encoding: NSUTF8StringEncoding, error: nil)!
        configuration.userContentController.addUserScript(WKUserScript(source: userScript, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: true))
        configuration.userContentController.addScriptMessageHandler(self, name: "turbolinks")

        self.delegate?.prepareWebViewConfiguration(configuration, forSession: self)

        let webView = TLWebView(frame: CGRectZero, configuration: configuration)
        webView.setTranslatesAutoresizingMaskIntoConstraints(false)
        webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal

        return webView
    }()
    
    // MARK: Visiting

    private var currentVisit: TLVisit? { didSet { println("currentVisit = \(currentVisit)") } }
    private var lastIssuedVisit: TLVisit? { didSet { println("lastIssuedVisit = \(lastIssuedVisit)") } }

    public func visit(location: NSURL) {
        if let visitable = delegate?.visitableForSession(self, atLocation: location) {
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
            
            self.lastIssuedVisit?.cancel()
            self.lastIssuedVisit = visit

            visit.delegate = self
            visit.startRequest()
        }
    }
    
    private func requestForLocation(location: NSURL) -> NSURLRequest {
        return delegate?.requestForSession(self, atLocation: location) ?? NSURLRequest(URL: location)
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
        if let visit = self.currentVisit where visit === lastIssuedVisit {
            visit.completeNavigation()
        }
    }
    
    private func webViewRendered() {
        if let visit = self.currentVisit where visit === lastIssuedVisit {
            visit.finish()
        }
    }
    
    // MARK: VisitDelegate
    
    func visitDidStart(visit: TLVisit) {
        if currentVisit == nil {
            self.currentVisit = lastIssuedVisit
        }

        let visitable = visit.visitable
        visitable.showScreenshot()
        visitable.showActivityIndicator()
    }

    func visitDidFail(visit: TLVisit) {
        let visitable = visit.visitable
        visitable.deactivateWebView()
    }

    func visitDidFinish(visit: TLVisit) {
        if visit.completed {
            let visitable = visit.visitable
            visitable.hideScreenshot()
            visitable.hideActivityIndicator()
        }

        if refreshing {
            self.refreshing = false
            currentVisitable?.didRefresh()
        }
   }
    
    func visitWillIssueRequest(visit: TLVisit) {
        delegate?.sessionWillIssueRequest(self)
    }
    
    func visit(visit: TLVisit, didFailRequestWithError error: NSError) {
        delegate?.session(self, didFailRequestForVisitable: visit.visitable, withError: error)
    }

    func visit(visit: TLVisit, didFailRequestWithStatusCode statusCode: Int) {
        delegate?.session(self, didFailRequestForVisitable: visit.visitable, withStatusCode: statusCode)
    }

    func visit(visit: TLVisit, didCompleteRequestWithResponse response: String) {
        loadResponse(response)
    }
    
    func visitDidCompleteWebViewLoad(visit: TLVisit) {
        self.initialized = true
        delegate?.session(self, didInitializeWebView: webView)
    }
   
    func visitDidFinishRequest(visit: TLVisit) {
        delegate?.sessionDidFinishRequest(self)
    }

    private func loadResponse(response: String) {
        webView.callJavaScriptFunction("Turbolinks.controller.loadResponse", withArguments: [response]) { (result, error) -> () in
            self.webView.callJavaScriptFunction("Turbolinks.controller.adapter.notifyOfNextRender")
        }
    }
    
    // MARK: VisitableDelegate

    public func visitableViewWillDisappear(visitable: TLVisitable) {
        visitable.updateScreenshot()
    }

    public func visitableViewWillAppear(visitable: TLVisitable) {
        if let currentVisitable = self.currentVisitable, currentVisit = self.currentVisit, lastIssuedVisit = self.lastIssuedVisit {
            if currentVisitable === visitable {
                // Back swipe gesture canceled
                if currentVisit.succeeded {
                    // Top visitable was fully loaded before the gesture began
                    lastIssuedVisit.cancel()
                } else {
                    // Top visitable was *not* fully loaded before the gesture began
                    issueVisitForVisitable(visitable)
                }
            } else if lastIssuedVisit.visitable !== visitable || lastIssuedVisit.canceled {
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
        self.currentVisitable = visitable
        visitable.activateWebView(webView)

        if let visit = self.lastIssuedVisit where !visit.canceled {
            self.currentVisit = visit
        }
    }
    
    private func deactivateVisitable(visitable: TLVisitable) {
        visitable.deactivateWebView()
    }
    
    public func visitableDidRequestRefresh(visitable: TLVisitable) {
        self.initialized = false
        self.refreshing = true
        self.currentVisit = nil

        visitable.willRefresh()
        issueVisitForVisitable(visitable)
    }

    private func pushLocation(location: NSURL) {
        webView.callJavaScriptFunction("Turbolinks.controller.history.push", withArguments: [location.absoluteString!])
    }
}
