import WebKit

enum TLScriptMessageName: String {
    case VisitRequested = "visitRequested"
    case LocationChanged = "locationChanged"
    case SnapshotRestored = "snapshotRestored"
    case RequestCompleted = "requestCompleted"
    case RequestFailed = "requestFailed"
    case ResponseLoaded = "responseLoaded"
}

protocol TLWebViewDelegate: class {
    func webView(webView: TLWebView, didRequestVisitToLocation location: NSURL)
    func webView(webView: TLWebView, didNavigateToLocation location: NSURL)
    func webViewDidRestoreSnapshot(webView: TLWebView)
    func webViewDidLoadResponse(webView: TLWebView)
}

protocol TLRequestDelegate: class {
    func webView(webView: TLWebView, didReceiveResponse response: String)
    func webView(webView: TLWebView, requestDidFailWithStatusCode statusCode: Int?)
}

class TLWebView: WKWebView, WKScriptMessageHandler {
    weak var delegate: TLWebViewDelegate?
    weak var requestDelegate: TLRequestDelegate?

    init(configuration: WKWebViewConfiguration) {
        super.init(frame: CGRectZero, configuration: configuration)

        let bundle = NSBundle(forClass: self.dynamicType)
        let source = String(contentsOfURL: bundle.URLForResource("TLWebView", withExtension: "js")!, encoding: NSUTF8StringEncoding, error: nil)!
        let userScript = WKUserScript(source: source, injectionTime: .AtDocumentEnd, forMainFrameOnly: true)
        configuration.userContentController.addUserScript(userScript)
        configuration.userContentController.addScriptMessageHandler(self, name: "turbolinks")

        setTranslatesAutoresizingMaskIntoConstraints(false)
        scrollView.decelerationRate = UIScrollViewDecelerationRateNormal
    }

    func pushLocation(location: NSURL) {
        callJavaScriptFunction("webView.pushLocation", withArguments: [location.absoluteString!])
    }

    func ifSnapshotExistsForLocation(location: NSURL, completion: () -> ()) {
        callJavaScriptFunction("webView.hasSnapshotForLocation", withArguments: [location.absoluteString!]) { (result, error) -> () in
            if let hasSnapshot = result as? Bool where hasSnapshot {
                dispatch_async(dispatch_get_main_queue(), completion)
            }
        }
    }

    func restoreSnapshotByScrollingToSavedPosition(scrollToSavedPosition: Bool) {
        callJavaScriptFunction("webView.restoreSnapshotByScrollingToSavedPosition", withArguments: [scrollToSavedPosition])
    }

    func issueRequestForLocation(location: NSURL) {
        callJavaScriptFunction("webView.issueRequestForLocation", withArguments: [location.absoluteString!])
    }

    func abortCurrentRequest() {
        callJavaScriptFunction("webView.abortCurrentRequest")
    }

    func loadResponse(response: String) {
        callJavaScriptFunction("webView.loadResponse", withArguments: [response])
    }

    // MARK: WKScriptMessageHandler

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if let body = message.body as? [String: AnyObject],
            rawName = body["name"] as? String,
            name = TLScriptMessageName(rawValue: rawName) {
                switch name {
                case .VisitRequested:
                    if let data = body["data"] as? String, location = NSURL(string: data) {
                        delegate?.webView(self, didRequestVisitToLocation: location)
                    }
                case .LocationChanged:
                    if let data = body["data"] as? String, location = NSURL(string: data) {
                        delegate?.webView(self, didNavigateToLocation: location)
                    }
                case .SnapshotRestored:
                    delegate?.webViewDidRestoreSnapshot(self)
                case .RequestCompleted:
                    if let response = body["data"] as? String {
                        requestDelegate?.webView(self, didReceiveResponse: response)
                    }
                case .RequestFailed:
                    let statusCode = body["data"] as? Int
                    requestDelegate?.webView(self, requestDidFailWithStatusCode: statusCode)
                case .ResponseLoaded:
                    delegate?.webViewDidLoadResponse(self)
                }
        }
    }

    // MARK: JavaScript Evaluation

    private func callJavaScriptFunction(functionExpression: String, withArguments arguments: [AnyObject] = [], completionHandler: ((AnyObject?, NSError?) -> ())? = { (_, _) -> () in }) {
        if let script = scriptForCallingJavaScriptFunction(functionExpression, withArguments: arguments) {
            evaluateJavaScript(script, completionHandler: completionHandler)
        } else {
            println("Error encoding arguments for JavaScript function `\(functionExpression)'")
        }
    }

    private func scriptForCallingJavaScriptFunction(functionExpression: String, withArguments arguments: [AnyObject]) -> String? {
        if let encodedArguments = encodeJavaScriptArguments(arguments) {
            return functionExpression + "(" + encodedArguments + ")"
        }
        return nil
    }

    private func encodeJavaScriptArguments(arguments: [AnyObject]) -> String? {
        if let data = NSJSONSerialization.dataWithJSONObject(arguments, options: nil, error: nil),
            string = NSString(data: data, encoding: NSUTF8StringEncoding) as? String {
                return string[Range(start: string.startIndex.successor(), end: string.endIndex.predecessor())]
        }
        return nil
    }
}