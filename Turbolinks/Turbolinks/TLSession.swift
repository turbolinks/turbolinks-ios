import UIKit
import WebKit

public protocol TLSessionDelegate: class {
    func prepareWebViewConfiguration(configuration: WKWebViewConfiguration, forSession session: TLSession)
    func session(session: TLSession, didRequestVisitForLocation location: NSURL)
    
    func sessionWillIssueRequest(session: TLSession)
    func session(session: TLSession, didFailRequestForVisitable visitable: TLVisitable, withError error: NSError)
    func session(session: TLSession, didFailRequestForVisitable visitable: TLVisitable, withStatusCode statusCode: Int)
    func sessionDidFinishRequest(session: TLSession)
    func session(session: TLSession, didInitializeWebView webView: WKWebView)
}

public class TLSession: NSObject, TLWebViewDelegate, TLVisitDelegate, TLVisitableDelegate {
    public weak var delegate: TLSessionDelegate?

    var initialized: Bool = false
    var refreshing: Bool = false

    var currentVisitable: TLVisitable?

    lazy var webView: TLWebView = {
        let configuration = WKWebViewConfiguration()
        self.delegate?.prepareWebViewConfiguration(configuration, forSession: self)
        let webView = TLWebView(configuration: configuration)
        webView.delegate = self
        return webView
    }()
    
    // MARK: Visiting

    private var currentVisit: TLVisit? { didSet { println("currentVisit = \(currentVisit)") } }
    private var lastIssuedVisit: TLVisit? { didSet { println("lastIssuedVisit = \(lastIssuedVisit)") } }

    private func visitLocation(location: NSURL) {
        delegate?.session(self, didRequestVisitForLocation: location)
    }

    public func visitVisitable(visitable: TLVisitable) {
        issueVisitForVisitable(visitable, direction: .Forward)
    }
    
    public func reloadCurrentVisitable() {
        if let visitable = currentVisitable {
            initialized = false
            currentVisit = nil
            visitVisitable(visitable)
            activateVisitable(visitable)
        }
    }

    private func issueVisitForVisitable(visitable: TLVisitable, direction: TLVisitDirection) {
        if let location = visitable.location {
            let visit: TLVisit

            if initialized {
                visit = TLTurbolinksVisit(visitable: visitable, direction: direction, webView: webView)
            } else {
                visit = TLWebViewVisit(visitable: visitable, direction: direction, webView: webView)
            }
            
            lastIssuedVisit?.cancel()
            lastIssuedVisit = visit

            visit.delegate = self
            visit.startRequest()
        }
    }
    
    // MARK: TLWebViewDelegate

    func webView(webView: TLWebView, didRequestVisitToLocation location: NSURL) {
        visitLocation(location)
    }

    func webView(webView: TLWebView, didNavigateToLocation location: NSURL) {
        if let visit = currentVisit where visit.location == location {
            visit.completeNavigation()
            webView.restoreSnapshotByScrollingToSavedPosition(visit.direction == .Backward)
        }
    }

    func webView(webView: TLWebView, didRestoreSnapshotForLocation location: NSURL) {
        if let visitable = currentVisitable where visitable.location == location {
            visitable.hideScreenshot()
            visitable.hideActivityIndicator()
            visitable.didBecomeInteractive()
        }
    }

    func webView(webView: TLWebView, didLoadResponseForLocation location: NSURL) {
        if let visit = currentVisit where visit.location == location {
            visit.finish()
        }
    }

    func webViewDidInvalidatePage(webView: TLWebView) {
        if let visit = currentVisit, visitable = currentVisitable {
            visitable.updateScreenshot()
            visit.cancel()

            visitable.showScreenshot()
            visitable.showActivityIndicator()

            reloadCurrentVisitable()
        }
    }

    // MARK: TLVisitDelegate
    
    func visitDidStart(visit: TLVisit) {
        if currentVisit == nil {
            currentVisit = lastIssuedVisit
        }

        let visitable = visit.visitable
        visitable.showScreenshot()
        visitable.showActivityIndicator()

        if let location = visitable.location where visit.direction == .Backward {
            webView.ifSnapshotExistsForLocation(location) {
                visitable.hideActivityIndicator()
            }
        }
    }

    func visitDidFail(visit: TLVisit) {
        deactivateVisitable(visit.visitable)
    }

    func visitDidFinish(visit: TLVisit) {
        let visitable = visit.visitable

        if visit.completed {
            visitable.hideScreenshot()
            visitable.hideActivityIndicator()
            visitable.didBecomeInteractive()
        }

        if refreshing {
            refreshing = false
            visitable.didRefresh()
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
        webView.loadResponse(response)
    }
    
    func visitDidCompleteWebViewLoad(visit: TLVisit) {
        initialized = true
        delegate?.session(self, didInitializeWebView: webView)
    }
   
    func visitDidFinishRequest(visit: TLVisit) {
        delegate?.sessionDidFinishRequest(self)
    }

    // MARK: TLVisitableDelegate

    public func visitableViewWillDisappear(visitable: TLVisitable) {
        visitable.updateScreenshot()
    }

    public func visitableViewWillAppear(visitable: TLVisitable) {
        if let currentVisitable = self.currentVisitable, currentVisit = self.currentVisit, lastIssuedVisit = self.lastIssuedVisit {
            if visitable === currentVisitable && visitable.viewController.isMovingToParentViewController() {
                // Back swipe gesture canceled
                if currentVisit.succeeded {
                    // Top visitable was fully loaded before the gesture began
                    lastIssuedVisit.cancel()
                } else {
                    // Top visitable was *not* fully loaded before the gesture began
                    issueVisitForVisitable(visitable, direction: .Forward)
                }
            } else if lastIssuedVisit.visitable !== visitable || lastIssuedVisit.canceled {
                // Navigating backward
                issueVisitForVisitable(visitable, direction: .Backward)
            }
        }
    }
    
    public func visitableViewDidDisappear(visitable: TLVisitable) {
        deactivateVisitable(visitable)
    }

    public func visitableViewDidAppear(visitable: TLVisitable) {
        if let location = visitable.location {
            activateVisitable(visitable)
            webView.pushLocation(location)
        }
    }

    public func visitableDidRequestRefresh(visitable: TLVisitable) {
        if visitable === currentVisitable {
            refreshing = true
            visitable.willRefresh()
            reloadCurrentVisitable()
        }
    }

    private func activateVisitable(visitable: TLVisitable) {
        currentVisitable = visitable

        if let visit = lastIssuedVisit where !visit.canceled {
            currentVisit = visit
        }

        if !webView.isDescendantOfView(visitable.viewController.view) {
            visitable.activateWebView(webView)
        }
    }

    private func deactivateVisitable(visitable: TLVisitable) {
        visitable.deactivateWebView()
    }
}
