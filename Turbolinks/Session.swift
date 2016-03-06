import UIKit
import WebKit

public protocol SessionDelegate: class {
    func session(session: Session, didProposeVisitToURL URL: NSURL, withAction action: Action)
    func session(session: Session, didFailRequestForVisitable visitable: Visitable, withError error: NSError)
    func sessionDidLoadWebView(session: Session)
    func sessionDidStartRequest(session: Session)
    func sessionDidFinishRequest(session: Session)
}

public extension SessionDelegate {
    func sessionDidLoadWebView(session: Session) {
        session.webView.navigationDelegate = session
    }

    func sessionDidStartRequest(session: Session) {
    }

    func sessionDidFinishRequest(session: Session) {
    }
}

public class Session: NSObject {
    public weak var delegate: SessionDelegate?

    public var webView: WKWebView {
        return _webView
    }

    private var _webView: WebView
    private var initialized = false
    private var refreshing = false

    public init(webViewConfiguration: WKWebViewConfiguration) {
        _webView = WebView(configuration: webViewConfiguration)
        super.init()
        _webView.delegate = self
    }

    // MARK: Visiting

    private var currentVisit: Visit?
    private var topmostVisit: Visit?

    public var topmostVisitable: Visitable? {
        return topmostVisit?.visitable
    }

    public func visit(visitable: Visitable) {
        visitVisitable(visitable, action: .Advance)
    }
    
    private func visitVisitable(visitable: Visitable, action: Action) {
        guard visitable.visitableURL != nil else { return }

        visitable.visitableDelegate = self

        let visit: Visit

        if initialized {
            visit = JavaScriptVisit(visitable: visitable, action: action, webView: _webView)
            visit.restorationIdentifier = restorationIdentifierForVisitable(visitable)
        } else {
            visit = ColdBootVisit(visitable: visitable, action: action, webView: _webView)
        }

        currentVisit?.cancel()
        currentVisit = visit

        visit.delegate = self
        visit.start()
    }

    public func reload() {
        if let visitable = topmostVisitable {
            initialized = false
            visit(visitable)
            topmostVisit = currentVisit
        }
    }

    // MARK: Visitable activation

    private var activatedVisitable: Visitable?

    private func activateVisitable(visitable: Visitable) {
        if visitable !== activatedVisitable {
            if let activatedVisitable = self.activatedVisitable {
                deactivateVisitable(activatedVisitable, showScreenshot: true)
            }

            visitable.activateVisitableWebView(webView)
            activatedVisitable = visitable
        }
    }

    private func deactivateVisitable(visitable: Visitable, showScreenshot: Bool = false) {
        if visitable === activatedVisitable {
            if showScreenshot {
                visitable.updateVisitableScreenshot()
                visitable.showVisitableScreenshot()
            }

            visitable.deactivateVisitableWebView()
            activatedVisitable = nil
        }
    }

    // MARK: Visitable restoration identifiers

    private var visitableRestorationIdentifiers = NSMapTable(keyOptions: .WeakMemory, valueOptions: .StrongMemory)

    private func restorationIdentifierForVisitable(visitable: Visitable) -> String? {
        return visitableRestorationIdentifiers.objectForKey(visitable) as? String
    }

    private func storeRestorationIdentifier(restorationIdentifier: String, forVisitable visitable: Visitable) {
        visitableRestorationIdentifiers.setObject(restorationIdentifier, forKey: visitable)
    }

    private func completeNavigationForCurrentVisit() {
        if let visit = currentVisit {
            topmostVisit = visit
            visit.completeNavigation()
        }
    }
}

extension Session: VisitDelegate {
    func visitRequestDidStart(visit: Visit) {
        delegate?.sessionDidStartRequest(self)
    }

    func visitRequestDidFinish(visit: Visit) {
        delegate?.sessionDidFinishRequest(self)
    }

    func visit(visit: Visit, requestDidFailWithError error: NSError) {
        delegate?.session(self, didFailRequestForVisitable: visit.visitable, withError: error)
    }

    func visitDidInitializeWebView(visit: Visit) {
        initialized = true
        delegate?.sessionDidLoadWebView(self)
        visit.visitable.visitableDidRender()
    }

    func visitWillStart(visit: Visit) {
        visit.visitable.showVisitableScreenshot()
        activateVisitable(visit.visitable)
    }

    func visitDidStart(visit: Visit) {
        if !visit.hasCachedSnapshot {
            visit.visitable.showVisitableActivityIndicator()
        }
    }

    func visitWillLoadResponse(visit: Visit) {
        visit.visitable.updateVisitableScreenshot()
        visit.visitable.showVisitableScreenshot()
    }

    func visitDidRender(visit: Visit) {
        visit.visitable.hideVisitableScreenshot()
        visit.visitable.hideVisitableActivityIndicator()
        visit.visitable.visitableDidRender()
    }

    func visitDidComplete(visit: Visit) {
        if let restorationIdentifier = visit.restorationIdentifier {
            storeRestorationIdentifier(restorationIdentifier, forVisitable: visit.visitable)
        }
    }

    func visitDidFail(visit: Visit) {
        visit.visitable.clearVisitableScreenshot()
        visit.visitable.showVisitableScreenshot()
    }

    func visitDidFinish(visit: Visit) {
        if refreshing {
            refreshing = false
            visit.visitable.visitableDidRefresh()
        }
    }
}

extension Session: VisitableDelegate {
    public func visitableViewWillAppear(visitable: Visitable) {
        guard let topmostVisit = self.topmostVisit, currentVisit = self.currentVisit else { return }

        if visitable === topmostVisit.visitable && visitable.visitableViewController.isMovingToParentViewController() {
            // Back swipe gesture canceled
            if topmostVisit.state == .Completed {
                currentVisit.cancel()
            } else {
                visitVisitable(visitable, action: .Advance)
            }
        } else if visitable === currentVisit.visitable && currentVisit.state == .Started {
            // Navigating forward - complete navigation early
            completeNavigationForCurrentVisit()
        } else if visitable !== topmostVisit.visitable {
            // Navigating backward
            visitVisitable(visitable, action: .Restore)
        }
    }

    public func visitableViewDidAppear(visitable: Visitable) {
        if let currentVisit = self.currentVisit where visitable === currentVisit.visitable {
            // Appearing after successful navigation
            completeNavigationForCurrentVisit()
            if currentVisit.state != .Failed {
                activateVisitable(visitable)
            }
        } else if let topmostVisit = self.topmostVisit where visitable === topmostVisit.visitable && topmostVisit.state == .Completed {
            // Reappearing after canceled navigation
            visitable.hideVisitableScreenshot()
            visitable.hideVisitableActivityIndicator()
            activateVisitable(visitable)
        }
    }

    public func visitableDidRequestReload(visitable: Visitable) {
        if visitable === topmostVisitable {
            reload()
        }
    }
   
    public func visitableDidRequestRefresh(visitable: Visitable) {
        if visitable === topmostVisitable {
            refreshing = true
            visitable.visitableWillRefresh()
            reload()
        }
    }
}

extension Session: WebViewDelegate {
    func webView(webView: WebView, didProposeVisitToLocation location: NSURL, withAction action: Action) {
        delegate?.session(self, didProposeVisitToURL: location, withAction: action)
    }
    
    func webViewDidInvalidatePage(webView: WebView) {
        if let visitable = topmostVisitable {
            visitable.updateVisitableScreenshot()
            visitable.showVisitableScreenshot()
            visitable.showVisitableActivityIndicator()
            reload()
        }
    }
    
    func webView(webView: WebView, didFailJavaScriptEvaluationWithError error: NSError) {
        if let currentVisit = self.currentVisit where initialized {
            initialized = false
            currentVisit.cancel()
            visit(currentVisit.visitable)
        }
    }
}

extension Session: WKNavigationDelegate {
    public func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> ()) {
        decisionHandler(WKNavigationActionPolicy.Cancel)

        if let URL = navigationAction.request.URL {
            UIApplication.sharedApplication().openURL(URL)
        }
    }
}
