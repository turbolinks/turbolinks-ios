import WebKit

let TLVisitErrorDomain = "com.basecamp.Turbolinks"

protocol TLVisitDelegate: class {
    func visitDidInitializeWebView(visit: TLVisit)

    func visitWillStart(visit: TLVisit)
    func visitDidStart(visit: TLVisit)
    func visitDidComplete(visit: TLVisit)
    func visitDidFail(visit: TLVisit)

    func visitDidRestoreSnapshot(visit: TLVisit)
    func visitDidLoadResponse(visit: TLVisit)

    func visitRequestDidStart(visit: TLVisit)
    func visit(visit: TLVisit, requestDidFailWithError error: NSError)
    func visit(visit: TLVisit, requestDidFailWithStatusCode statusCode: Int)
    func visitRequestDidFinish(visit: TLVisit)
}

enum TLVisitAction: String {
    case Advance = "advance"
    case Restore = "restore"
}

enum TLVisitState: String {
    case Initialized = "Initialized"
    case Started = "Started"
    case Canceled = "Canceled"
    case Failed = "Failed"
    case Completed = "Completed"
}

class TLVisit: NSObject {
    weak var delegate: TLVisitDelegate?

    var visitable: TLVisitable
    var action: TLVisitAction
    var webView: TLWebView
    var state: TLVisitState

    var location: NSURL
    var hasSnapshot: Bool = false

    override var description: String {
        return "<\(self.dynamicType): state=\(state.rawValue) location=\(location)>"
    }

    init(visitable: TLVisitable, action: TLVisitAction, webView: TLWebView) {
        self.visitable = visitable
        self.location = visitable.location!
        self.action = action
        self.webView = webView
        self.state = .Initialized
    }

    func start() {
        if state == .Initialized {
            delegate?.visitWillStart(self)
            self.state = .Started
            startVisit()
            NSLog("\(self) start()")
        }
    }

    func cancel() {
        if state == .Started {
            self.state = .Canceled
            cancelVisit()
            NSLog("\(self) cancel()")
        }
    }

    private func complete() {
        if state == .Started {
            self.state = .Completed
            delegate?.visitDidComplete(self)
            NSLog("\(self) complete()")
        }
    }

    private func fail(callback: (() -> ())? = nil) {
        if state == .Started {
            self.state = .Failed
            callback?()
            delegate?.visitDidFail(self)
            NSLog("\(self) fail()")
        }
    }

    private func startVisit() {}
    private func cancelVisit() {}

    // MARK: Navigation

    private lazy var navigationLock: TLLock = {
        return TLLock(queue: dispatch_get_main_queue())
    }()

    func completeNavigation() {
        if state == .Started {
            navigationLock.unlock()
            NSLog("\(self) completeNavigation()")
        }
    }

    private func afterNavigationCompletion(callback: () -> ()) {
        navigationLock.afterUnlock() {
            if self.state != .Canceled {
                callback()
            }
        }
    }
}

class TLColdBootVisit: TLVisit, WKNavigationDelegate {
    override private func startVisit() {
        webView.navigationDelegate = self
        webView.loadRequest(NSURLRequest(URL: location))
        delegate?.visitDidStart(self)
    }

    override private func cancelVisit() {
        webView.stopLoading()
    }

    // MARK: WKNavigationDelegate

    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        webView.navigationDelegate = nil
        delegate?.visitDidInitializeWebView(self)
        complete()
    }

    func webView(webView: WKWebView, decidePolicyForNavigationResponse navigationResponse: WKNavigationResponse, decisionHandler: (WKNavigationResponsePolicy) -> Void) {
        if let httpResponse = navigationResponse.response as? NSHTTPURLResponse {
            if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                decisionHandler(.Allow)
            } else {
                decisionHandler(.Cancel)
                fail { self.delegate?.visit(self, requestDidFailWithStatusCode: httpResponse.statusCode) }
            }
        }
    }

    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        fail { self.delegate?.visit(self, requestDidFailWithError: error) }
    }

    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        fail { self.delegate?.visit(self, requestDidFailWithError: error) }
    }
}

class TLJavaScriptVisit: TLVisit, TLWebViewVisitDelegate {
    var identifier: String = "(pending)"

    override var description: String {
        return "<\(self.dynamicType) \(identifier): state=\(state.rawValue) location=\(location)>"
    }

    override private func startVisit() {
        webView.visitDelegate = self
        webView.visitLocation(location, withAction: action.rawValue)
    }

    override private func cancelVisit() {
        webView.cancelVisit()
    }

    // MARK: TLWebViewVisitDelegate

    func webView(webView: TLWebView, didStartVisitWithIdentifier identifier: String, hasSnapshot: Bool) {
        self.identifier = identifier
        self.hasSnapshot = hasSnapshot

        delegate?.visitDidStart(self)
        webView.issueRequest()

        afterNavigationCompletion {
            self.webView.changeHistory()
            self.webView.restoreSnapshot()
        }
    }

    func webView(webView: TLWebView, didRestoreSnapshotForVisitWithIdentifier identifier: String) {
        delegate?.visitDidRestoreSnapshot(self)
    }


    func webView(webView: TLWebView, didStartRequestForVisitWithIdentifier identifier: String) {
        delegate?.visitRequestDidStart(self)
    }

    func webView(webView: TLWebView, didCompleteRequestForVisitWithIdentifier identifier: String) {
        afterNavigationCompletion {
            self.webView.loadResponse()
        }
    }

    func webView(webView: TLWebView, didFailRequestForVisitWithIdentifier identifier: String, withStatusCode statusCode: Int?) {
        fail {
            if statusCode == nil {
                let error = NSError(domain: TLVisitErrorDomain, code: 0, userInfo: nil)
                self.delegate?.visit(self, requestDidFailWithError: error)
            } else {
                self.delegate?.visit(self, requestDidFailWithStatusCode: statusCode!)
            }
        }
    }

    func webView(webView: TLWebView, didFinishRequestForVisitWithIdentifier identifier: String) {
        delegate?.visitRequestDidFinish(self)
    }

    func webView(webView: TLWebView, didLoadResponseForVisitWithIdentifier identifier: String) {
        delegate?.visitDidLoadResponse(self)
    }

    func webView(webView: TLWebView, didCompleteVisitWithIdentifier identifier: String) {
        complete()
    }
}
