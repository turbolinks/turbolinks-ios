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

public class TLSession: NSObject, TLWebViewDelegate, TLVisitDelegate, TLVisitableDelegate {
    public weak var delegate: TLSessionDelegate?

    var initialized: Bool = false
    var refreshing: Bool = false

    var currentVisitable: TLVisitable?

    lazy var webView: TLWebView = {
        let webView = TLWebView()
        webView.delegate = self
        self.delegate?.prepareWebViewConfiguration(webView.configuration, forSession: self)
        return webView
    }()
    
    // MARK: Visiting

    private var currentVisit: TLVisit? { didSet { println("currentVisit = \(currentVisit)") } }
    private var lastIssuedVisit: TLVisit? { didSet { println("lastIssuedVisit = \(lastIssuedVisit)") } }

    public func visitLocation(location: NSURL) {
        if let visitable = delegate?.visitableForSession(self, atLocation: location) {
            if presentVisitable(visitable) {
                issueVisitForVisitable(visitable, direction: .Forward)
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
    
    private func issueVisitForVisitable(visitable: TLVisitable, direction: TLVisitDirection) {
        if let location = visitable.location {
            let visit: TLVisit
            let request = requestForLocation(location)
            
            if initialized {
                visit = TLTurbolinksVisit(visitable: visitable, direction: direction, request: request)
            } else {
                visit = TLWebViewVisit(visitable: visitable, direction: direction, request: request, webView: webView)
            }
            
            lastIssuedVisit?.cancel()
            self.lastIssuedVisit = visit

            visit.delegate = self
            visit.startRequest()
        }
    }
    
    private func requestForLocation(location: NSURL) -> NSURLRequest {
        return delegate?.requestForSession(self, atLocation: location) ?? NSURLRequest(URL: location)
    }

    // MARK: TLWebViewDelegate

    func webView(webView: TLWebView, didRequestVisitToLocation location: NSURL) {
        visitLocation(location)
    }

    func webView(webView: TLWebView, didNavigateToLocation location: NSURL) {
        if let visit = self.currentVisit where visit === lastIssuedVisit {
            visit.completeNavigation()
            webView.restoreSnapshotByScrollingToSavedPosition(visit.direction == .Backward)
        }
    }

    func webViewDidRestoreSnapshot(webView: TLWebView) {
        if let visitable = self.currentVisitable {
            visitable.hideScreenshot()
            visitable.hideActivityIndicator()
        }
    }

    func webViewDidLoadResponse(webView: TLWebView) {
        if let visit = self.currentVisit where visit === lastIssuedVisit {
            visit.finish()
        }
    }
    
    // MARK: TLVisitDelegate
    
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
        webView.loadResponse(response)
    }
    
    func visitDidCompleteWebViewLoad(visit: TLVisit) {
        self.initialized = true
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
            if currentVisitable === visitable {
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
        issueVisitForVisitable(visitable, direction: .Forward)
    }
}
