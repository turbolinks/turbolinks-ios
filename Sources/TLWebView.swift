import WebKit

protocol TLWebViewDelegate: class {
    func webView(webView: TLWebView, didProposeVisitToLocation location: NSURL, withAction action: TLAction)
    func webViewDidInvalidatePage(webView: TLWebView)
    func webView(webView: TLWebView, didFailJavaScriptEvaluationWithError error: NSError)
}

protocol TLWebViewPageLoadDelegate: class {
    func webView(webView: TLWebView, didLoadPageWithRestorationIdentifier restorationIdentifier: String)
}

protocol TLWebViewVisitDelegate: class {
    func webView(webView: TLWebView, didStartVisitWithIdentifier identifier: String, hasSnapshot: Bool)
    func webView(webView: TLWebView, didRestoreSnapshotForVisitWithIdentifier identifier: String)
    func webView(webView: TLWebView, didStartRequestForVisitWithIdentifier identifier: String)
    func webView(webView: TLWebView, didCompleteRequestForVisitWithIdentifier identifier: String)
    func webView(webView: TLWebView, didFailRequestForVisitWithIdentifier identifier: String, statusCode: Int)
    func webView(webView: TLWebView, didFinishRequestForVisitWithIdentifier identifier: String)
    func webView(webView: TLWebView, didLoadResponseForVisitWithIdentifier identifier: String)
    func webView(webView: TLWebView, didCompleteVisitWithIdentifier identifier: String, restorationIdentifier: String)
}

class TLWebView: WKWebView, WKScriptMessageHandler {
    weak var delegate: TLWebViewDelegate?
    weak var pageLoadDelegate: TLWebViewPageLoadDelegate?
    weak var visitDelegate: TLWebViewVisitDelegate?

    init(configuration: WKWebViewConfiguration) {
        super.init(frame: CGRectZero, configuration: configuration)

        let bundle = NSBundle(forClass: self.dynamicType)
        let source = try! String(contentsOfURL: bundle.URLForResource("TLWebView", withExtension: "js")!, encoding: NSUTF8StringEncoding)
        let userScript = WKUserScript(source: source, injectionTime: .AtDocumentEnd, forMainFrameOnly: true)
        configuration.userContentController.addUserScript(userScript)
        configuration.userContentController.addScriptMessageHandler(self, name: "turbolinks")

        translatesAutoresizingMaskIntoConstraints = false
        scrollView.decelerationRate = UIScrollViewDecelerationRateNormal
    }

    func visitLocation(location: NSURL, withAction action: TLAction, restorationIdentifier: String?) {
        callJavaScriptFunction("webView.visitLocationWithActionAndRestorationIdentifier", withArguments: [location.absoluteString, action.rawValue, restorationIdentifier])
    }

    func issueRequestForVisitWithIdentifier(identifier: String) {
        callJavaScriptFunction("webView.issueRequestForVisitWithIdentifier", withArguments: [identifier])
    }

    func changeHistoryForVisitWithIdentifier(identifier: String) {
        callJavaScriptFunction("webView.changeHistoryForVisitWithIdentifier", withArguments: [identifier])
    }

    func restoreSnapshotForVisitWithIdentifier(identifier: String) {
        callJavaScriptFunction("webView.restoreSnapshotForVisitWithIdentifier", withArguments: [identifier])
    }

    func loadResponseForVisitWithIdentifier(identifier: String) {
        callJavaScriptFunction("webView.loadResponseForVisitWithIdentifier", withArguments: [identifier])
    }

    func cancelVisitWithIdentifier(identifier: String) {
        callJavaScriptFunction("webView.cancelVisitWithIdentifier", withArguments: [identifier])
    }

    // MARK: WKScriptMessageHandler

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if let message = TLScriptMessage.parse(message) {
            switch message.name {
            case .PageLoaded:
                pageLoadDelegate?.webView(self, didLoadPageWithRestorationIdentifier: message.restorationIdentifier!)
            case .ErrorRaised:
                let error = message.data["error"] as? String
                NSLog("JavaScript error: %@", error ?? "<unknown error>")
            case .VisitProposed:
                delegate?.webView(self, didProposeVisitToLocation: message.location!, withAction: message.action!)
            case .PageInvalidated:
                delegate?.webViewDidInvalidatePage(self)
            case .VisitStarted:
                visitDelegate?.webView(self, didStartVisitWithIdentifier: message.identifier!, hasSnapshot: message.data["hasSnapshot"] as! Bool)
            case .VisitSnapshotRestored:
                visitDelegate?.webView(self, didRestoreSnapshotForVisitWithIdentifier: message.identifier!)
            case .VisitRequestStarted:
                visitDelegate?.webView(self, didStartRequestForVisitWithIdentifier: message.identifier!)
            case .VisitRequestCompleted:
                visitDelegate?.webView(self, didCompleteRequestForVisitWithIdentifier: message.identifier!)
            case .VisitRequestFailed:
                visitDelegate?.webView(self, didFailRequestForVisitWithIdentifier: message.identifier!, statusCode: message.data["statusCode"] as! Int)
            case .VisitRequestFinished:
                visitDelegate?.webView(self, didFinishRequestForVisitWithIdentifier: message.identifier!)
            case .VisitResponseLoaded:
                visitDelegate?.webView(self, didLoadResponseForVisitWithIdentifier: message.identifier!)
            case .VisitCompleted:
                visitDelegate?.webView(self, didCompleteVisitWithIdentifier: message.identifier!, restorationIdentifier: message.restorationIdentifier!)
            }
        }
    }

    // MARK: JavaScript Evaluation

    private func callJavaScriptFunction(functionExpression: String, withArguments arguments: [AnyObject?] = [], completionHandler: ((AnyObject?) -> ())? = nil) {
        if let script = scriptForCallingJavaScriptFunction(functionExpression, withArguments: arguments) {
            evaluateJavaScript(script) { (result, error) in
                if let result = result as? Dictionary<String, AnyObject> {
                    if let error = result["error"] as? String, stack = result["stack"] as? String {
                        NSLog("Error evaluating JavaScript function `%@': %@\n%@", functionExpression, error, stack)
                    } else {
                        completionHandler?(result["value"])
                    }
                } else if let error = error {
                    self.delegate?.webView(self, didFailJavaScriptEvaluationWithError: error)
                }
            }
        } else {
            NSLog("Error encoding arguments for JavaScript function `%@'", functionExpression)
        }
    }

    private func scriptForCallingJavaScriptFunction(functionExpression: String, withArguments arguments: [AnyObject?]) -> String? {
        if let encodedArguments = encodeJavaScriptArguments(arguments) {
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
        return nil
    }

    private func encodeJavaScriptArguments(arguments: [AnyObject?]) -> String? {
        let arguments = arguments.map { $0 == nil ? NSNull() : $0! }

        if let data = try? NSJSONSerialization.dataWithJSONObject(arguments, options: []),
            string = NSString(data: data, encoding: NSUTF8StringEncoding) as? String {
                return string[Range(start: string.startIndex.successor(), end: string.endIndex.predecessor())]
        }
        return nil
    }
}