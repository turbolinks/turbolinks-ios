import WebKit

let TLVisitErrorDomain = "com.basecamp.Turbolinks"

protocol TLVisitDelegate: class {
    func visitDidStart(visit: TLVisit)
    func visitDidFail(visit: TLVisit)
    func visitDidFinish(visit: TLVisit)

    func visitWillIssueRequest(visit: TLVisit)
    func visit(visit: TLVisit, didFailRequestWithError error: NSError)
    func visit(visit: TLVisit, didFailRequestWithStatusCode statusCode: Int)
    func visit(visit: TLVisit, didCompleteRequestWithResponse response: String)
    func visitDidCompleteWebViewLoad(visit: TLVisit)
    func visitDidFinishRequest(visit: TLVisit)
}

enum TLVisitDirection: String {
    case Forward = "Forward"
    case Backward = "Backward"
}

class TLVisit: NSObject {
    var visitable: TLVisitable
    var direction: TLVisitDirection
    var request: NSURLRequest
    weak var delegate: TLVisitDelegate?
    
    enum State: String {
        case Initialized = "Initialized"
        case Started = "Started"
        case Completed = "Completed"
        case Canceled = "Canceled"
    }
    
    var requestState: State = .Initialized
    var navigationState: State = .Started

    var finished: Bool = false

    var completed: Bool {
        return finished && !canceled
    }
    
    var canceled: Bool {
        return finished && (requestState == .Canceled || navigationState == .Canceled)
    }
    
    var failed: Bool = false

    var succeeded: Bool {
        return completed && !failed
    }

    init(visitable: TLVisitable, direction: TLVisitDirection, request: NSURLRequest) {
        self.visitable = visitable
        self.direction = direction
        self.request = request
    }
    
    func cancel() {
        cancelRequest()
        cancelNavigation()
        finish()
    }

    func fail() {
        if !finished && !failed {
            self.failed = true
            delegate?.visitDidFail(self)
            finish()
        }
    }

    func finish() {
        if !finished {
            println("\(self) finish()")
            self.finished = true
            completeRequest()
            completeNavigation()
            delegate?.visitDidFinish(self)
        }
    }
    
    func startRequest() {
        if requestState == .Initialized {
            println("\(self) startRequest()")
            self.requestState = .Started
            delegate?.visitDidStart(self)
            delegate?.visitWillIssueRequest(self)
            issueRequest()
        }
    }
    
    func completeRequest() {
        if requestState == .Started {
            println("\(self) completeRequest()")
            self.requestState = .Completed
            delegate?.visitDidFinishRequest(self)
        }
    }
    
    func cancelRequest() {
        if requestState == .Started {
            println("\(self) cancelRequest()")
            self.requestState = .Canceled
            abortRequest()
            delegate?.visitDidFinishRequest(self)
            finish()
        }
    }
    
    func completeNavigation() {
        if navigationState == .Started {
            println("\(self) completeNavigation()")
            self.navigationState = .Completed
            navigationLock.unlock()
        }
    }
    
    func cancelNavigation() {
        if navigationState == .Started {
            println("\(self) cancelNavigation()")
            self.navigationState = .Canceled
            cancelRequest()
            finish()
        }
    }
    
    private func issueRequest() {}
    private func abortRequest() {}
    
    private lazy var navigationLock: TLLock = {
        return TLLock(queue: dispatch_get_main_queue())
    }()
    
    private func afterNavigationCompletion(callback: () -> ()) {
        navigationLock.afterUnlock(callback)
    }
}

class TLWebViewVisit: TLVisit, WKNavigationDelegate {
    var webView: WKWebView
    
    init(visitable: TLVisitable, direction: TLVisitDirection, request: NSURLRequest, webView: WKWebView) {
        self.webView = webView
        super.init(visitable: visitable, direction: direction, request: request)
    }
    
    override private func issueRequest() {
        webView.navigationDelegate = self
        webView.loadRequest(request)
    }
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        webView.navigationDelegate = nil
        delegate?.visitDidCompleteWebViewLoad(self)
        finish()
    }

    func webView(webView: WKWebView, decidePolicyForNavigationResponse navigationResponse: WKNavigationResponse, decisionHandler: (WKNavigationResponsePolicy) -> Void) {
        if let httpResponse = navigationResponse.response as? NSHTTPURLResponse {
            if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                decisionHandler(.Allow)
            } else {
                decisionHandler(.Cancel)
                delegate?.visit(self, didFailRequestWithStatusCode: httpResponse.statusCode)
                fail()
            }
        }
    }

    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        if !failed {
            delegate?.visit(self, didFailRequestWithError: error)
            fail()
        }
    }

    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        if !failed {
            delegate?.visit(self, didFailRequestWithError: error)
            fail()
        }
    }
}

class TLTurbolinksVisit: TLVisit {
    private var sessionTask: NSURLSessionTask?
    
    override private func issueRequest() {
        if sessionTask == nil {
            let session = NSURLSession.sharedSession()
            self.sessionTask = session.dataTaskWithRequest(request) { (data, response, error) in
                let body = NSString(data: data, encoding: NSUTF8StringEncoding) as? String
                dispatch_async(dispatch_get_main_queue()) {
                    self.handleResponse(response, body: body, error: error)
                    self.completeRequest()
                }
            }
            
            sessionTask?.resume()
        }
    }
    
    override private func abortRequest() {
        sessionTask?.cancel()
        self.sessionTask = nil
    }

    private func handleResponse(response: NSURLResponse?, body: String?, error: NSError!) {
        if body == nil {
            handleError(NSError(domain: TLVisitErrorDomain, code: 0, userInfo: nil))
        } else if error != nil {
            handleError(error)
        } else if let httpResponse = response as? NSHTTPURLResponse {
            handleHTTPResponse(httpResponse, body: body!)
        }
    }

    private func handleHTTPResponse(httpResponse: NSHTTPURLResponse, body: String) {
        afterNavigationCompletion() {
            if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                self.delegate?.visit(self, didCompleteRequestWithResponse: body)
            } else {
                self.delegate?.visit(self, didFailRequestWithStatusCode: httpResponse.statusCode)
                self.fail()
            }
        }
    }

    private func handleError(error: NSError) {
        delegate?.visit(self, didFailRequestWithError: error)
        fail()
    }
}
