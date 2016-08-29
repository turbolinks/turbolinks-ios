import WebKit

protocol WebViewDelegate: class {
    func webView(webView: WebView, didProposeVisitToLocation location: NSURL, withAction action: Action)
    func webViewDidInvalidatePage(webView: WebView)
    func webView(webView: WebView, didFailJavaScriptEvaluationWithError error: NSError)
}

protocol WebViewPageLoadDelegate: class {
    func webView(webView: WebView, didLoadPageWithRestorationIdentifier restorationIdentifier: String)
}

protocol WebViewVisitDelegate: class {
    func webView(webView: WebView, didStartVisitWithIdentifier identifier: String, hasCachedSnapshot: Bool)
    func webView(webView: WebView, didStartRequestForVisitWithIdentifier identifier: String)
    func webView(webView: WebView, didCompleteRequestForVisitWithIdentifier identifier: String)
    func webView(webView: WebView, didFailRequestForVisitWithIdentifier identifier: String, statusCode: Int)
    func webView(webView: WebView, didFinishRequestForVisitWithIdentifier identifier: String)
    func webView(webView: WebView, didRenderForVisitWithIdentifier identifier: String)
    func webView(webView: WebView, didCompleteVisitWithIdentifier identifier: String, restorationIdentifier: String)
}

class WebView: WKWebView {
    weak var delegate: WebViewDelegate?
    weak var pageLoadDelegate: WebViewPageLoadDelegate?
    weak var visitDelegate: WebViewVisitDelegate?

    init(configuration: WKWebViewConfiguration) {
        super.init(frame: CGRectZero, configuration: configuration)

        let bundle = NSBundle(forClass: self.dynamicType)
        let source = try! String(contentsOfURL: bundle.URLForResource("WebView", withExtension: "js")!, encoding: NSUTF8StringEncoding)
        let userScript = WKUserScript(source: source, injectionTime: .AtDocumentEnd, forMainFrameOnly: true)
        configuration.userContentController.addUserScript(userScript)
        configuration.userContentController.addScriptMessageHandler(self, name: "turbolinks")

        translatesAutoresizingMaskIntoConstraints = false
        scrollView.decelerationRate = UIScrollViewDecelerationRateNormal
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func visitLocation(location: NSURL, withAction action: Action, restorationIdentifier: String?) {
        callJavaScriptFunction("webView.visitLocationWithActionAndRestorationIdentifier", withArguments: [location.absoluteString, action.rawValue, restorationIdentifier])
    }

    func issueRequestForVisitWithIdentifier(identifier: String) {
        callJavaScriptFunction("webView.issueRequestForVisitWithIdentifier", withArguments: [identifier])
    }

    func changeHistoryForVisitWithIdentifier(identifier: String) {
        callJavaScriptFunction("webView.changeHistoryForVisitWithIdentifier", withArguments: [identifier])
    }

    func loadCachedSnapshotForVisitWithIdentifier(identifier: String) {
        callJavaScriptFunction("webView.loadCachedSnapshotForVisitWithIdentifier", withArguments: [identifier])
    }

    func loadResponseForVisitWithIdentifier(identifier: String) {
        callJavaScriptFunction("webView.loadResponseForVisitWithIdentifier", withArguments: [identifier])
    }

    func cancelVisitWithIdentifier(identifier: String) {
        callJavaScriptFunction("webView.cancelVisitWithIdentifier", withArguments: [identifier])
    }

    // MARK: JavaScript Evaluation

    private func callJavaScriptFunction(functionExpression: String, withArguments arguments: [AnyObject?] = [], completionHandler: ((AnyObject?) -> ())? = nil) {
        guard let script = scriptForCallingJavaScriptFunction(functionExpression, withArguments: arguments) else {
            NSLog("Error encoding arguments for JavaScript function `%@'", functionExpression)
            return
        }
        
        evaluateJavaScript(script) { (result, error) in
            if let result = result as? [String: AnyObject] {
                if let error = result["error"] as? String, stack = result["stack"] as? String {
                    NSLog("Error evaluating JavaScript function `%@': %@\n%@", functionExpression, error, stack)
                } else {
                    completionHandler?(result["value"])
                }
            } else if let error = error {
                self.delegate?.webView(self, didFailJavaScriptEvaluationWithError: error)
            }
        }
    }

    private func scriptForCallingJavaScriptFunction(functionExpression: String, withArguments arguments: [AnyObject?]) -> String? {
        guard let encodedArguments = encodeJavaScriptArguments(arguments) else { return nil }

        return
            "(function(result) {\n" +
            "  try {\n" +
            "    result.value = " + functionExpression + "(" + encodedArguments + ")\n" +
            "  } catch (error) {\n" +
            "    result.error = error.toString()\n" +
            "    result.stack = error.stack\n" +
            "  }\n" +
            "  return result\n" +
            "})({})"
    }

    private func encodeJavaScriptArguments(arguments: [AnyObject?]) -> String? {
        let arguments = arguments.map { $0 == nil ? NSNull() : $0! }

        if let data = try? NSJSONSerialization.dataWithJSONObject(arguments, options: []),
            string = NSString(data: data, encoding: NSUTF8StringEncoding) as? String {
                return string[string.startIndex.successor() ..< string.endIndex.predecessor()]
        }
        
        return nil
    }
}

extension WebView: WKScriptMessageHandler {
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        guard let message = ScriptMessage.parse(message) else { return }
        
        switch message.name {
        case .PageLoaded:
            pageLoadDelegate?.webView(self, didLoadPageWithRestorationIdentifier: message.restorationIdentifier!)
        case .PageInvalidated:
            delegate?.webViewDidInvalidatePage(self)
        case .VisitProposed:
            delegate?.webView(self, didProposeVisitToLocation: message.location!, withAction: message.action!)
        case .VisitStarted:
            visitDelegate?.webView(self, didStartVisitWithIdentifier: message.identifier!, hasCachedSnapshot: message.data["hasCachedSnapshot"] as! Bool)
        case .VisitRequestStarted:
            visitDelegate?.webView(self, didStartRequestForVisitWithIdentifier: message.identifier!)
        case .VisitRequestCompleted:
            visitDelegate?.webView(self, didCompleteRequestForVisitWithIdentifier: message.identifier!)
        case .VisitRequestFailed:
            visitDelegate?.webView(self, didFailRequestForVisitWithIdentifier: message.identifier!, statusCode: message.data["statusCode"] as! Int)
        case .VisitRequestFinished:
            visitDelegate?.webView(self, didFinishRequestForVisitWithIdentifier: message.identifier!)
        case .VisitRendered:
            visitDelegate?.webView(self, didRenderForVisitWithIdentifier: message.identifier!)
        case .VisitCompleted:
            visitDelegate?.webView(self, didCompleteVisitWithIdentifier: message.identifier!, restorationIdentifier: message.restorationIdentifier!)
        case .ErrorRaised:
            let error = message.data["error"] as? String
            NSLog("JavaScript error: %@", error ?? "<unknown error>")
        }
    }
}
