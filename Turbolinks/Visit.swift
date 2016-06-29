import WebKit

protocol VisitDelegate: class {
    func visitDidInitializeWebView(_ visit: Visit)

    func visitWillStart(_ visit: Visit)
    func visitDidStart(_ visit: Visit)
    func visitDidComplete(_ visit: Visit)
    func visitDidFail(_ visit: Visit)
    func visitDidFinish(_ visit: Visit)

    func visitWillLoadResponse(_ visit: Visit)
    func visitDidRender(_ visit: Visit)

    func visitRequestDidStart(_ visit: Visit)
    func visit(_ visit: Visit, requestDidFailWithError error: NSError)
    func visitRequestDidFinish(_ visit: Visit)
}

enum VisitState {
    case initialized
    case started
    case canceled
    case failed
    case completed
}

class Visit: NSObject {
    weak var delegate: VisitDelegate?

    var visitable: Visitable
    var action: Action
    var webView: WebView
    var state: VisitState

    var location: URL
    var hasCachedSnapshot: Bool = false
    var restorationIdentifier: String?

    override var description: String {
        return "<\(self.dynamicType): state=\(state) location=\(location)>"
    }

    init(visitable: Visitable, action: Action, webView: WebView) {
        self.visitable = visitable
        self.location = visitable.visitableURL! as URL
        self.action = action
        self.webView = webView
        self.state = .initialized
    }

    func start() {
        if state == .initialized {
            delegate?.visitWillStart(self)
            state = .started
            startVisit()
        }
    }

    func cancel() {
        if state == .started {
            state = .canceled
            cancelVisit()
        }
    }

    private func complete() {
        if state == .started {
            state = .completed
            delegate?.visitDidComplete(self)
            delegate?.visitDidFinish(self)
        }
    }

    private func fail(_ callback: (() -> Void)? = nil) {
        if state == .started {
            state = .failed
            callback?()
            failVisit()
            delegate?.visitDidFail(self)
            delegate?.visitDidFinish(self)
        }
    }

    private func startVisit() {}
    private func cancelVisit() {}
    private func failVisit() {}

    // MARK: Navigation

    private var navigationCompleted = false
    private var navigationCallback: (() -> Void)?

    func completeNavigation() {
        if state == .started && !navigationCompleted {
            navigationCompleted = true
            navigationCallback?()
        }
    }

    private func afterNavigationCompletion(_ callback: () -> Void) {
        if navigationCompleted {
            callback()
        } else {
            let previousNavigationCallback = navigationCallback
            navigationCallback = { [unowned self] in
                previousNavigationCallback?()
                if self.state != .canceled {
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

        let request = URLRequest(url: location)
        navigation = webView.load(request)

        delegate?.visitDidStart(self)
        startRequest()
    }

    override private func cancelVisit() {
        removeNavigationDelegate()
        webView.stopLoading()
        finishRequest()
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

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if navigation === self.navigation {
            removeNavigationDelegate()
            delegate?.visitDidInitializeWebView(self)
            finishRequest()
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        // Ignore any clicked links before the cold boot finishes navigation
        if navigationAction.navigationType == .linkActivated {
            decisionHandler(.cancel)
            if let url = navigationAction.request.url {
                UIApplication.shared().openURL(url)
            }
        } else {
            decisionHandler(.allow)
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: (WKNavigationResponsePolicy) -> Void) {
        if let httpResponse = navigationResponse.response as? HTTPURLResponse {
            if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                decisionHandler(.allow)
            } else {
                decisionHandler(.cancel)
                fail {
                    let error = Error(code: .httpFailure, statusCode: httpResponse.statusCode)
                    self.delegate?.visit(self, requestDidFailWithError: error)
                }
            }
        } else {
            decisionHandler(.cancel)
            fail {
                let error = Error(code: .networkFailure, localizedDescription: "An unknown error occurred")
                self.delegate?.visit(self, requestDidFailWithError: error)
            }
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError originalError: NSError) {
        if navigation === self.navigation {
            fail {
                let error = Error(code: .networkFailure, error: originalError)
                self.delegate?.visit(self, requestDidFailWithError: error)
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError originalError: NSError) {
        if navigation === self.navigation {
            fail {
                let error = Error(code: .networkFailure, error: originalError)
                self.delegate?.visit(self, requestDidFailWithError: error)
            }
        }
    }

    // MARK: WebViewPageLoadDelegate

    func webView(_ webView: WebView, didLoadPageWithRestorationIdentifier restorationIdentifier: String) {
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

    func webView(_ webView: WebView, didStartVisitWithIdentifier identifier: String, hasCachedSnapshot: Bool) {
        self.identifier = identifier
        self.hasCachedSnapshot = hasCachedSnapshot

        delegate?.visitDidStart(self)
        webView.issueRequestForVisitWithIdentifier(identifier)

        afterNavigationCompletion { [unowned self] in
            self.webView.changeHistoryForVisitWithIdentifier(identifier)
            self.webView.loadCachedSnapshotForVisitWithIdentifier(identifier)
        }
    }

    func webView(_ webView: WebView, didStartRequestForVisitWithIdentifier identifier: String) {
        if identifier == self.identifier {
            startRequest()
        }
    }

    func webView(_ webView: WebView, didCompleteRequestForVisitWithIdentifier identifier: String) {
        if identifier == self.identifier {
            afterNavigationCompletion { [unowned self] in
                self.delegate?.visitWillLoadResponse(self)
                self.webView.loadResponseForVisitWithIdentifier(identifier)
            }
        }
    }

    func webView(_ webView: WebView, didFailRequestForVisitWithIdentifier identifier: String, statusCode: Int) {
        if identifier == self.identifier {
            fail {
                let error: NSError
                if statusCode == 0 {
                    error = Error(code: .networkFailure, localizedDescription: "A network error occurred.")
                } else {
                    error = Error(code: .httpFailure, statusCode: statusCode)
                }
                self.delegate?.visit(self, requestDidFailWithError: error)
            }
        }
    }

    func webView(_ webView: WebView, didFinishRequestForVisitWithIdentifier identifier: String) {
        if identifier == self.identifier {
            finishRequest()
        }
    }

    func webView(_ webView: WebView, didRenderForVisitWithIdentifier identifier: String) {
        if identifier == self.identifier {
            delegate?.visitDidRender(self)
        }
    }

    func webView(_ webView: WebView, didCompleteVisitWithIdentifier identifier: String, restorationIdentifier: String) {
        if identifier == self.identifier {
            self.restorationIdentifier = restorationIdentifier
            complete()
        }
    }
}
