import UIKit
import WebKit

public protocol TLSessionDelegate: class {
    func prepareWebViewConfiguration(configuration: WKWebViewConfiguration, forSession session: TLSession)

    func session(session: TLSession, didInitializeWebView webView: WKWebView)
    func session(session: TLSession, didProposeVisitToLocation location: NSURL, withAction action: TLAction)
    
    func sessionDidStartRequest(session: TLSession)
    func session(session: TLSession, didFailRequestForVisitable visitable: TLVisitable, withError error: NSError)
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
                visit.restorationIdentifier = restorationIdentifierForVisitable(visitable)
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
            visit(visitable)
            topmostVisit = currentVisit
        }
    }

    // MARK: Visitable activation

    private var activatedVisitable: TLVisitable?

    func activateVisitable(visitable: TLVisitable) {
        if visitable !== activatedVisitable {
            if let activatedVisitable = self.activatedVisitable {
                deactivateVisitable(activatedVisitable, showScreenshot: true)
            }

            visitable.activateWebView(webView)
            activatedVisitable = visitable
        }
    }

    func deactivateVisitable(visitable: TLVisitable, showScreenshot: Bool = false) {
        if visitable === activatedVisitable {
            if showScreenshot {
                visitable.updateScreenshot()
                visitable.showScreenshot()
            }

            visitable.deactivateWebView()
            activatedVisitable = nil
        }
    }

    // MARK: Visitable restoration identifiers

    private var visitableRestorationIdentifiers = NSMapTable(keyOptions: .WeakMemory, valueOptions: .StrongMemory)

    func restorationIdentifierForVisitable(visitable: TLVisitable) -> String? {
        return visitableRestorationIdentifiers.objectForKey(visitable) as? String
    }

    func storeRestorationIdentifier(restorationIdentifier: String, forVisitable visitable: TLVisitable) {
        visitableRestorationIdentifiers.setObject(restorationIdentifier, forKey: visitable)
    }

    // MARK: TLWebViewDelegate

    func webView(webView: TLWebView, didProposeVisitToLocation location: NSURL, withAction action: TLAction) {
        delegate?.session(self, didProposeVisitToLocation: location, withAction: action)
    }

    func webViewDidInvalidatePage(webView: TLWebView) {
        if let visitable = topmostVisitable {
            visitable.updateScreenshot()
            topmostVisit?.cancel()

            visitable.showScreenshot()
            visitable.showActivityIndicator()

            reload()
        }
    }

    func webView(webView: TLWebView, didFailJavaScriptEvaluationWithError error: NSError) {
        if let currentVisit = self.currentVisit where initialized {
            self.initialized = false
            currentVisit.cancel()
            visit(currentVisit.visitable)
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
        if let restorationIdentifier = visit.restorationIdentifier {
            storeRestorationIdentifier(restorationIdentifier, forVisitable: visit.visitable)
        }

        if refreshing {
            refreshing = false
            visit.visitable.didRefresh()
        }
    }

    func visitDidFail(visit: TLVisit) {
        deactivateVisitable(visit.visitable)
    }

    // MARK: TLVisitDelegate networking

    func visitRequestDidStart(visit: TLVisit) {
        delegate?.sessionDidStartRequest(self)
    }

    func visitRequestDidFinish(visit: TLVisit) {
        delegate?.sessionDidFinishRequest(self)
    }

    func visit(visit: TLVisit, requestDidFailWithError error: NSError) {
        delegate?.session(self, didFailRequestForVisitable: visit.visitable, withError: error)
    }

    // MARK: TLVisitableDelegate

    public func visitableViewWillAppear(visitable: TLVisitable) {
        if let topmostVisit = self.topmostVisit, currentVisit = self.currentVisit {
            if visitable === topmostVisit.visitable && visitable.viewController.isMovingToParentViewController() {
                // Back swipe gesture canceled
                NSLog("%@ Backward navigation canceled", self)
                if topmostVisit.state == .Completed {
                    currentVisit.cancel()
                } else {
                    visitVisitable(visitable, action: .Advance)
                }
            } else if visitable === currentVisit.visitable && currentVisit.state == .Started {
                // Navigating forward - complete navigation early
                NSLog("%@ Navigating forward", self)
                completeNavigationForCurrentVisit()
            } else if visitable !== topmostVisit.visitable {
                // Navigating backward
                NSLog("%@ Navigating backward", self)
                visitVisitable(visitable, action: .Restore)
            }
        }
    }
    
    public func visitableViewDidAppear(visitable: TLVisitable) {
        if visitable === currentVisit?.visitable {
            // Appearing after successful navigation
            completeNavigationForCurrentVisit()
            if currentVisit!.state != .Failed {
                activateVisitable(visitable)
            }
        } else if visitable === topmostVisit?.visitable && topmostVisit?.state == .Completed {
            // Reappearing after canceled navigation
            visitable.hideScreenshot()
            visitable.hideActivityIndicator()
            activateVisitable(visitable)
        }
    }

    public func visitableDidRequestRefresh(visitable: TLVisitable) {
        if visitable === topmostVisitable {
            refreshing = true
            visitable.willRefresh()
            reload()
        }
    }

    private func completeNavigationForCurrentVisit() {
        if let visit = currentVisit {
            topmostVisit = visit
            visit.completeNavigation()
        }
    }
}
