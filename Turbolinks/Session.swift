import UIKit
import WebKit

public protocol SessionDelegate: class {
    func session(_ session: Session, didProposeVisitToURL url: URL, withAction action: Action)
    func session(_ session: Session, didFailRequestForVisitable visitable: Visitable, withError error: NSError)
    func session(_ session: Session, openExternalURL url: URL)
    func sessionDidLoadWebView(_ session: Session)
    func sessionDidStartRequest(_ session: Session)
    func sessionDidFinishRequest(_ session: Session)
}

public extension SessionDelegate {
    func sessionDidLoadWebView(_ session: Session) {
        session.webView.navigationDelegate = session
    }

    func session(_ session: Session, openExternalURL url: URL) {
        UIApplication.shared().openURL(url)
    }

    func sessionDidStartRequest(_ session: Session) {
    }

    func sessionDidFinishRequest(_ session: Session) {
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

    public convenience override init() {
        self.init(webViewConfiguration: WKWebViewConfiguration())
    }
   
    // MARK: Visiting

    private var currentVisit: Visit?
    private var topmostVisit: Visit?

    public var topmostVisitable: Visitable? {
        return topmostVisit?.visitable
    }

    public func visit(_ visitable: Visitable) {
        visitVisitable(visitable, action: .Advance)
    }
    
    private func visitVisitable(_ visitable: Visitable, action: Action) {
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

    private func activateVisitable(_ visitable: Visitable) {
        if visitable !== activatedVisitable {
            if let activatedVisitable = self.activatedVisitable {
                deactivateVisitable(activatedVisitable, showScreenshot: true)
            }

            visitable.activateVisitableWebView(webView)
            activatedVisitable = visitable
        }
    }

    private func deactivateVisitable(_ visitable: Visitable, showScreenshot: Bool = false) {
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

    private var visitableRestorationIdentifiers: MapTable<UIViewController, NSString> = MapTable(keyOptions: PointerFunctions.Options.weakMemory, valueOptions: PointerFunctions.Options.strongMemory)

    private func restorationIdentifierForVisitable(_ visitable: Visitable) -> String? {
        return visitableRestorationIdentifiers.object(forKey: visitable.visitableViewController) as? String
    }

    private func storeRestorationIdentifier(_ restorationIdentifier: String, forVisitable visitable: Visitable) {
        visitableRestorationIdentifiers.setObject(restorationIdentifier, forKey: visitable.visitableViewController)
    }

    private func completeNavigationForCurrentVisit() {
        if let visit = currentVisit {
            topmostVisit = visit
            visit.completeNavigation()
        }
    }
}

extension Session: VisitDelegate {
    func visitRequestDidStart(_ visit: Visit) {
        delegate?.sessionDidStartRequest(self)
    }

    func visitRequestDidFinish(_ visit: Visit) {
        delegate?.sessionDidFinishRequest(self)
    }

    func visit(_ visit: Visit, requestDidFailWithError error: NSError) {
        delegate?.session(self, didFailRequestForVisitable: visit.visitable, withError: error)
    }

    func visitDidInitializeWebView(_ visit: Visit) {
        initialized = true
        delegate?.sessionDidLoadWebView(self)
        visit.visitable.visitableDidRender()
    }

    func visitWillStart(_ visit: Visit) {
        visit.visitable.showVisitableScreenshot()
        activateVisitable(visit.visitable)
    }

    func visitDidStart(_ visit: Visit) {
        if !visit.hasCachedSnapshot {
            visit.visitable.showVisitableActivityIndicator()
        }
    }

    func visitWillLoadResponse(_ visit: Visit) {
        visit.visitable.updateVisitableScreenshot()
        visit.visitable.showVisitableScreenshot()
    }

    func visitDidRender(_ visit: Visit) {
        visit.visitable.hideVisitableScreenshot()
        visit.visitable.hideVisitableActivityIndicator()
        visit.visitable.visitableDidRender()
    }

    func visitDidComplete(_ visit: Visit) {
        if let restorationIdentifier = visit.restorationIdentifier {
            storeRestorationIdentifier(restorationIdentifier, forVisitable: visit.visitable)
        }
    }

    func visitDidFail(_ visit: Visit) {
        visit.visitable.clearVisitableScreenshot()
        visit.visitable.showVisitableScreenshot()
    }

    func visitDidFinish(_ visit: Visit) {
        if refreshing {
            refreshing = false
            visit.visitable.visitableDidRefresh()
        }
    }
}

extension Session: VisitableDelegate {
    public func visitableViewWillAppear(_ visitable: Visitable) {
        guard let topmostVisit = self.topmostVisit, currentVisit = self.currentVisit else { return }

        if visitable === topmostVisit.visitable && visitable.visitableViewController.isMovingToParentViewController() {
            // Back swipe gesture canceled
            if topmostVisit.state == .completed {
                currentVisit.cancel()
            } else {
                visitVisitable(visitable, action: .Advance)
            }
        } else if visitable === currentVisit.visitable && currentVisit.state == .started {
            // Navigating forward - complete navigation early
            completeNavigationForCurrentVisit()
        } else if visitable !== topmostVisit.visitable {
            // Navigating backward
            visitVisitable(visitable, action: .Restore)
        }
    }

    public func visitableViewDidAppear(_ visitable: Visitable) {
        if let currentVisit = self.currentVisit where visitable === currentVisit.visitable {
            // Appearing after successful navigation
            completeNavigationForCurrentVisit()
            if currentVisit.state != .failed {
                activateVisitable(visitable)
            }
        } else if let topmostVisit = self.topmostVisit where visitable === topmostVisit.visitable && topmostVisit.state == .completed {
            // Reappearing after canceled navigation
            visitable.hideVisitableScreenshot()
            visitable.hideVisitableActivityIndicator()
            activateVisitable(visitable)
        }
    }

    public func visitableDidRequestReload(_ visitable: Visitable) {
        if visitable === topmostVisitable {
            reload()
        }
    }
   
    public func visitableDidRequestRefresh(_ visitable: Visitable) {
        if visitable === topmostVisitable {
            refreshing = true
            visitable.visitableWillRefresh()
            reload()
        }
    }
}

extension Session: WebViewDelegate {
    func webView(_ webView: WebView, didProposeVisitToLocation location: URL, withAction action: Action) {
        delegate?.session(self, didProposeVisitToURL: location, withAction: action)
    }
    
    func webViewDidInvalidatePage(_ webView: WebView) {
        if let visitable = topmostVisitable {
            visitable.updateVisitableScreenshot()
            visitable.showVisitableScreenshot()
            visitable.showVisitableActivityIndicator()
            reload()
        }
    }
    
    func webView(_ webView: WebView, didFailJavaScriptEvaluationWithError error: NSError) {
        if let currentVisit = self.currentVisit where initialized {
            initialized = false
            currentVisit.cancel()
            visit(currentVisit.visitable)
        }
    }
}

extension Session: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> ()) {
        let navigationDecision = NavigationDecision(navigationAction: navigationAction)
        decisionHandler(navigationDecision.policy)

        if let url = navigationDecision.externallyOpenableURL {
            openExternalURL(url)
        } else if navigationDecision.shouldReloadPage {
            reload()
        }
    }

    private struct NavigationDecision {
        let navigationAction: WKNavigationAction

        var policy: WKNavigationActionPolicy {
            return isMainFrameNavigation ? .cancel : .allow
        }

        var externallyOpenableURL: URL? {
            if let url = navigationAction.request.url where shouldOpenURLExternally {
                return url
            } else {
                return nil
            }
        }

        var shouldOpenURLExternally: Bool {
            let type = navigationAction.navigationType
            return isMainFrameNavigation && (type == .linkActivated || type == .other)
        }

        var shouldReloadPage: Bool {
            let type = navigationAction.navigationType
            return isMainFrameNavigation && type == .reload
        }

        var isMainFrameNavigation: Bool {
            return navigationAction.targetFrame?.isMainFrame ?? false
        }
    }
    
    private func openExternalURL(_ url: URL) {
        delegate?.session(self, openExternalURL: url)
    }
}
