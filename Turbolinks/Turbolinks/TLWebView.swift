import WebKit

protocol TLWebViewDelegate: class {
    func webView(webView: TLWebView, didProposeVisitToLocation location: NSURL)
    func webViewDidInvalidatePage(webView: TLWebView)
}

protocol TLWebViewVisitDelegate: class {
    func webView(webView: TLWebView, didStartVisitWithIdentifier identifier: String, hasSnapshot: Bool)
    func webViewVisitDidRestoreSnapshot(webView: TLWebView)
    func webViewVisitRequestDidStart(webview: TLWebView)
    func webViewVisitRequestDidComplete(webView: TLWebView)
    func webView(webView: TLWebView, visitRequestDidFailWithStatusCode statusCode: Int?)
    func webViewVisitRequestDidFinish(webView: TLWebView)
    func webViewVisitDidLoadResponse(webView: TLWebView)
    func webViewVisitDidComplete(webView: TLWebView)
}

class TLWebView: WKWebView, WKScriptMessageHandler {
    weak var delegate: TLWebViewDelegate?
    weak var visitDelegate: TLWebViewVisitDelegate?

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

    func visitLocation(location: NSURL, withAction action: String) {
        callJavaScriptFunction("webView.visitLocationWithAction", withArguments: [location.absoluteString!, action])
    }

    func issueRequest() {
        callJavaScriptFunction("webView.issueRequest")
    }

    func changeHistory() {
        callJavaScriptFunction("webView.changeHistory")
    }

    func restoreSnapshot() {
        callJavaScriptFunction("webView.restoreSnapshot")
    }

    func loadResponse() {
        callJavaScriptFunction("webView.loadResponse")
    }

    func cancelVisit() {
        callJavaScriptFunction("webView.cancelVisit")
    }

    // MARK: WKScriptMessageHandler

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if let message = TLScriptMessage.parse(message) {
            switch message.name {
            case .VisitProposed:
                if let location = message.location {
                    delegate?.webView(self, didProposeVisitToLocation: location)
                }
            case .VisitStarted:
                if let identifier = message.identifier, hasSnapshot = message.data["hasSnapshot"] as? Bool {
                    visitDelegate?.webView(self, didStartVisitWithIdentifier: identifier, hasSnapshot: hasSnapshot)
                }
            case .VisitSnapshotRestored:
                visitDelegate?.webViewVisitDidRestoreSnapshot(self)
            case .VisitRequestStarted:
                visitDelegate?.webViewVisitRequestDidStart(self)
            case .VisitRequestCompleted:
                visitDelegate?.webViewVisitRequestDidComplete(self)
            case .VisitRequestFailed:
                let statusCode = message.data["statusCode"] as? Int
                visitDelegate?.webView(self, visitRequestDidFailWithStatusCode: statusCode)
            case .VisitRequestFinished:
                visitDelegate?.webViewVisitRequestDidFinish(self)
            case .VisitResponseLoaded:
                visitDelegate?.webViewVisitDidLoadResponse(self)
            case .VisitCompleted:
                visitDelegate?.webViewVisitDidComplete(self)
            case .PageInvalidated:
                delegate?.webViewDidInvalidatePage(self)
            case .Error:
                if let error = message.data["error"] as? String {
                    NSLog("JavaScript error: \(error)")
                }
            }
        }
    }

    // MARK: JavaScript Evaluation

    private func callJavaScriptFunction(functionExpression: String, withArguments arguments: [AnyObject] = [], completionHandler: ((AnyObject?) -> ())? = nil) {
        if let script = scriptForCallingJavaScriptFunction(functionExpression, withArguments: arguments) {
            evaluateJavaScript(script) { (result, error) in
                if let result = result as? Dictionary<String, AnyObject> {
                    if let error = result["error"] as? String, stack = result["stack"] as? String {
                        NSLog("Error evaluating JavaScript function `\(functionExpression)': \(error)\n\(stack)")
                    } else {
                        completionHandler?(result["value"])
                    }
                }

            }
        } else {
            NSLog("Error encoding arguments for JavaScript function `\(functionExpression)'")
        }
    }

    private func scriptForCallingJavaScriptFunction(functionExpression: String, withArguments arguments: [AnyObject]) -> String? {
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

    private func encodeJavaScriptArguments(arguments: [AnyObject]) -> String? {
        if let data = NSJSONSerialization.dataWithJSONObject(arguments, options: nil, error: nil),
            string = NSString(data: data, encoding: NSUTF8StringEncoding) as? String {
                return string[Range(start: string.startIndex.successor(), end: string.endIndex.predecessor())]
        }
        return nil
    }
}