import UIKit
import WebKit

public protocol TLSessionDelegate: class {
    func prepareWebViewConfiguration(configuration: WKWebViewConfiguration, forSession session: TLSession)

    func session(session: TLSession, didInitializeWebView webView: WKWebView)
    func session(session: TLSession, didProposeVisitToLocation location: NSURL, withAction action: TLAction)
    
    func sessionDidStartRequest(session: TLSession)
    func session(session: TLSession, didFailRequestForVisitable visitable: TLVisitable, withError error: NSError)
    func session(session: TLSession, didFailRequestForVisitable visitable: TLVisitable, withStatusCode statusCode: Int)
    func sessionDidFinishRequest(session: TLSession)
}

public class TLSession: NSObject, TLWebViewDelegate, TLVisitDelegate, TLVisitableDelegate {
    public weak var delegate: TLSessionDelegate?

    var initialized: Bool = false
    var refreshing: Bool = false

    lazy var webView: TLWebView = {
        let configuration = WKWebViewConfiguration()
        self.delegate?.prepareWebViewConfiguration(configuration, forSession: self)
        let webView = TLWebView(configuration: configuration)
        webView.delegate = self
        return webView
    }()
    
    // MARK: Visiting

    private var currentVisit: TLVisit?
    private var topmostVisit: TLVisit?

    private var activatedVisitable: TLVisitable?
    public var topmostVisitable: TLVisitable? {
        return topmostVisit?.visitable
    }

    public func visit(visitable: TLVisitable) {
        visitVisitable(visitable, action: .Advance)
    }
    
    func visitVisitable(visitable: TLVisitable, action: TLAction) {
        if visitable.location != nil {
            let visit: TLVisit

            if initialized {
                visit = TLJavaScriptVisit(visitable: visitable, action: action, webView: webView)
            } else {
                visit = TLColdBootVisit(visitable: visitable, action: action, webView: webView)
            }

            currentVisit?.cancel()
            currentVisit = visit

            visit.delegate = self
            visit.start()
        }
    }

    public func reload() {
        if let visitable = topmostVisitable {
            initialized = false
            visitVisitable(visitable, action: .Advance)
            activateVisitable(visitable)
        }
    }

    // MARK: TLWebViewDelegate

    func webView(webView: TLWebView, didProposeVisitToLocation location: NSURL, withAction action: TLAction) {
        delegate?.session(self, didProposeVisitToLocation: location, withAction: action)
    }

    func webViewDidInvalidatePage(webView: TLWebView) {
        if let visitable = activatedVisitable {
            visitable.updateScreenshot()
            topmostVisit?.cancel()

            visitable.showScreenshot()
            visitable.showActivityIndicator()

            reload()
        }
    }

    // MARK: TLVisitDelegate

    func visitDidInitializeWebView(visit: TLVisit) {
        initialized = true
        delegate?.session(self, didInitializeWebView: webView)
        visit.visitable.didLoadResponse?()
    }

    func visitWillStart(visit: TLVisit) {
        visit.visitable.showScreenshot()
        activateVisitable(visit.visitable)
    }
   
    func visitDidStart(visit: TLVisit) {
        if !visit.hasSnapshot {
            visit.visitable.showActivityIndicator()
        }
    }

    func visitDidRestoreSnapshot(visit: TLVisit) {
        visit.visitable.hideScreenshot()
        visit.visitable.hideActivityIndicator()
        visit.visitable.didRestoreSnapshot?()
    }

    func visitWillLoadResponse(visit: TLVisit) {
        visit.visitable.updateScreenshot()
        visit.visitable.showScreenshot()
    }

    func visitDidLoadResponse(visit: TLVisit) {
        visit.visitable.hideScreenshot()
        visit.visitable.hideActivityIndicator()
        visit.visitable.didLoadResponse?()
    }

    func visitDidComplete(visit: TLVisit) {
        if refreshing {
            refreshing = false
            visit.visitable.didRefresh()
        }
    }

    func visitDidFail(visit: TLVisit) {
        visit.visitable.hideScreenshot()
        visit.visitable.hideActivityIndicator()
        deactivateVisitable(visit.visitable)
    }

    // MARK: TLVisitDelegate - Request

    func visitRequestDidStart(visit: TLVisit) {
        delegate?.sessionDidStartRequest(self)
    }

    func visitRequestDidFinish(visit: TLVisit) {
        delegate?.sessionDidFinishRequest(self)
    }

    func visit(visit: TLVisit, requestDidFailWithError error: NSError) {
        delegate?.session(self, didFailRequestForVisitable: visit.visitable, withError: error)
    }

    func visit(visit: TLVisit, requestDidFailWithStatusCode statusCode: Int) {
        delegate?.session(self, didFailRequestForVisitable: visit.visitable, withStatusCode: statusCode)
    }

    // MARK: TLVisitableDelegate

    public func visitableViewWillAppear(visitable: TLVisitable) {
        if let topmostVisit = self.topmostVisit, currentVisit = self.currentVisit {
            if visitable.viewController.isMovingToParentViewController() {
                if visitable !== topmostVisit.visitable {
                    // Navigating forward - complete navigation early
                    self.topmostVisit = currentVisit
                    currentVisit.completeNavigation()
                } else {
                    // Back swipe gesture canceled
                    if topmostVisit.state == .Completed {
                        currentVisit.cancel()
                    } else {
                        visitVisitable(visitable, action: .Advance)
                    }
                }
            } else if visitable !== topmostVisit.visitable {
                // Navigating backward
                visitVisitable(visitable, action: .Restore)
            }
        }
    }
    
    public func visitableViewDidAppear(visitable: TLVisitable) {
        activateVisitable(visitable)

        if visitable === currentVisit?.visitable {
            // Appearing after successful navigation
            topmostVisit = currentVisit
            currentVisit!.completeNavigation()
        } else if visitable === topmostVisit?.visitable && topmostVisit?.state == .Completed {
            // Reappearing after canceled navigation
            visitable.hideActivityIndicator()
            visitable.hideScreenshot()
        }
    }

    public func visitableDidRequestRefresh(visitable: TLVisitable) {
        if visitable === activatedVisitable {
            refreshing = true
            visitable.willRefresh()
            reload()
        }
    }

    func activateVisitable(visitable: TLVisitable) {
        if visitable !== activatedVisitable {
            if let activatedVisitable = self.activatedVisitable {
                deactivateVisitable(activatedVisitable)
            }

            visitable.activateWebView(webView)
            self.activatedVisitable = visitable
        }
    }

    func deactivateVisitable(visitable: TLVisitable) {
        if visitable === activatedVisitable {
            visitable.updateScreenshot()
            visitable.showScreenshot()
            visitable.deactivateWebView()
            self.activatedVisitable = nil
        }
    }
}
