import WebKit

protocol VisitDelegate: class {
    func visitDidInitializeWebView(visit: Visit)

    func visitWillStart(visit: Visit)
    func visitDidStart(visit: Visit)
    func visitDidComplete(visit: Visit)
    func visitDidFail(visit: Visit)
    func visitDidFinish(visit: Visit)

    func visitWillLoadResponse(visit: Visit)
    func visitDidRender(visit: Visit)

    func visitRequestDidStart(visit: Visit)
    func visit(visit: Visit, requestDidFailWithError error: NSError)
    func visitRequestDidFinish(visit: Visit)
}

enum VisitState {
    case Initialized
    case Started
    case Canceled
    case Failed
    case Completed
}

class Visit: NSObject {
    weak var delegate: VisitDelegate?

    var visitable: Visitable
    var action: Action
    var webView: WebView
    var state: VisitState

    var location: NSURL
    var hasCachedSnapshot: Bool = false
    var restorationIdentifier: String?

    override var description: String {
        return "<\(self.dynamicType): state=\(state) location=\(location)>"
    }

    init(visitable: Visitable, action: Action, webView: WebView) {
        self.visitable = visitable
        self.location = visitable.visitableURL!
        self.action = action
        self.webView = webView
        self.state = .Initialized
    }

    func start() {
        if state == .Initialized {
            delegate?.visitWillStart(self)
            state = .Started
            startVisit()
        }
    }

    func cancel() {
        if state == .Started {
            state = .Canceled
            cancelVisit()
        }
    }

    private func complete() {
        if state == .Started {
            state = .Completed
            completeVisit()
            delegate?.visitDidComplete(self)
            delegate?.visitDidFinish(self)
        }
    }

    private func fail(callback: (() -> Void)? = nil) {
        if state == .Started {
            state = .Failed
            callback?()
            failVisit()
            delegate?.visitDidFail(self)
            delegate?.visitDidFinish(self)
        }
    }

    private func startVisit() {}
    private func cancelVisit() {}
    private func completeVisit() {}
    private func failVisit() {}

    // MARK: Navigation

    private var navigationCompleted = false
    private var navigationCallback: (() -> Void)?

    func completeNavigation() {
        if state == .Started && !navigationCompleted {
            navigationCompleted = true
            navigationCallback?()
        }
    }

    private func afterNavigationCompletion(callback: () -> Void) {
        if navigationCompleted {
            callback()
        } else {
            let previousNavigationCallback = navigationCallback
            navigationCallback = { [unowned self] in
                previousNavigationCallback?()
                if self.state != .Canceled {
                    callback()
                }
            }
        }
    }

    // MARK: Request state

    private var requestStarted = false
    private var requestFinished = false

    private func startRequest() {
        if !requestStarted {
            requestStarted = true
            delegate?.visitRequestDidStart(self)
        }
    }

    private func finishRequest() {
        if requestStarted && !requestFinished {
            requestFinished = true
            delegate?.visitRequestDidFinish(self)
        }
    }
}

class ColdBootVisit: Visit, WKNavigationDelegate, WebViewPageLoadDelegate {
    private var navigation: WKNavigation?

    override private func startVisit() {
        webView.navigationDelegate = self
        webView.pageLoadDelegate = self

        let request = NSURLRequest(URL: location)
        navigation = webView.loadRequest(request)

        delegate?.visitDidStart(self)
        startRequest()
    }

    override private func cancelVisit() {
        removeNavigationDelegate()
        webView.stopLoading()
        finishRequest()
    }

    override private func completeVisit() {
        removeNavigationDelegate()
        delegate?.visitDidInitializeWebView(self)
    }

    override private func failVisit() {
        removeNavigationDelegate()
        finishRequest()
    }

    private func removeNavigationDelegate() {
        if webView.navigationDelegate === self {
            webView.navigationDelegate = nil
        }
    }
    
    // MARK: WKNavigationDelegate

    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        if navigation === self.navigation {
            finishRequest()
        }
    }
    
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        // Ignore any clicked links before the cold boot finishes navigation
        if navigationAction.navigationType == .LinkActivated {
            decisionHandler(.Cancel)
            if let URL = navigationAction.request.URL {
                UIApplication.sharedApplication().openURL(URL)
            }
        } else {
            decisionHandler(.Allow)
        }
    }

    func webView(webView: WKWebView, decidePolicyForNavigationResponse navigationResponse: WKNavigationResponse, decisionHandler: (WKNavigationResponsePolicy) -> Void) {
        if let httpResponse = navigationResponse.response as? NSHTTPURLResponse {
            if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                decisionHandler(.Allow)
            } else {
                decisionHandler(.Cancel)
                fail {
                    let error = Error(code: .HTTPFailure, statusCode: httpResponse.statusCode)
                    self.delegate?.visit(self, requestDidFailWithError: error)
                }
            }
        } else {
            decisionHandler(.Cancel)
            fail {
                let error = Error(code: .NetworkFailure, localizedDescription: "An unknown error occurred")
                self.delegate?.visit(self, requestDidFailWithError: error)
            }
        }
    }

    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError originalError: NSError) {
        if navigation === self.navigation {
            fail {
                let error = Error(code: .NetworkFailure, error: originalError)
                self.delegate?.visit(self, requestDidFailWithError: error)
            }
        }
    }

    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError originalError: NSError) {
        if navigation === self.navigation {
            fail {
                let error = Error(code: .NetworkFailure, error: originalError)
                self.delegate?.visit(self, requestDidFailWithError: error)
            }
        }
    }

    // MARK: WebViewPageLoadDelegate

    func webView(webView: WebView, didLoadPageWithRestorationIdentifier restorationIdentifier: String) {
        self.restorationIdentifier = restorationIdentifier
        delegate?.visitDidRender(self)
        complete()
    }
}

class JavaScriptVisit: Visit, WebViewVisitDelegate {
    private var identifier = "(pending)"

    override var description: String {
        return "<\(self.dynamicType) \(identifier): state=\(state) location=\(location)>"
    }

    override private func startVisit() {
        webView.visitDelegate = self
        webView.visitLocation(location, withAction: action, restorationIdentifier: restorationIdentifier)
    }

    override private func cancelVisit() {
        webView.cancelVisitWithIdentifier(identifier)
        finishRequest()
    }

    override private func failVisit() {
        finishRequest()
    }

    // MARK: WebViewVisitDelegate

    func webView(webView: WebView, didStartVisitWithIdentifier identifier: String, hasCachedSnapshot: Bool) {
        self.identifier = identifier
        self.hasCachedSnapshot = hasCachedSnapshot

        delegate?.visitDidStart(self)
        webView.issueRequestForVisitWithIdentifier(identifier)

        afterNavigationCompletion { [unowned self] in
            self.webView.changeHistoryForVisitWithIdentifier(identifier)
            self.webView.loadCachedSnapshotForVisitWithIdentifier(identifier)
        }
    }

    func webView(webView: WebView, didStartRequestForVisitWithIdentifier identifier: String) {
        if identifier == self.identifier {
            startRequest()
        }
    }

    func webView(webView: WebView, didCompleteRequestForVisitWithIdentifier identifier: String) {
        if identifier == self.identifier {
            afterNavigationCompletion { [unowned self] in
                self.delegate?.visitWillLoadResponse(self)
                self.webView.loadResponseForVisitWithIdentifier(identifier)
            }
        }
    }

    func webView(webView: WebView, didFailRequestForVisitWithIdentifier identifier: String, statusCode: Int) {
        if identifier == self.identifier {
            fail {
                let error: NSError
                if statusCode == 0 {
                    error = Error(code: .NetworkFailure, localizedDescription: "A network error occurred.")
                } else {
                    error = Error(code: .HTTPFailure, statusCode: statusCode)
                }
                self.delegate?.visit(self, requestDidFailWithError: error)
            }
        }
    }

    func webView(webView: WebView, didFinishRequestForVisitWithIdentifier identifier: String) {
        if identifier == self.identifier {
            finishRequest()
        }
    }

    func webView(webView: WebView, didRenderForVisitWithIdentifier identifier: String) {
        if identifier == self.identifier {
            delegate?.visitDidRender(self)
        }
    }

    func webView(webView: WebView, didCompleteVisitWithIdentifier identifier: String, restorationIdentifier: String) {
        if identifier == self.identifier {
            self.restorationIdentifier = restorationIdentifier
            complete()
        }
    }
}
