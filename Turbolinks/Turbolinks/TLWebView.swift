import WebKit

protocol TLWebViewDelegate: class {
    func webView(webView: TLWebView, didProposeVisitToLocation location: NSURL)
    func webViewDidInvalidatePage(webView: TLWebView)
}

protocol TLWebViewVisitDelegate: class {
    func webView(webView: TLWebView, didStartVisitWithIdentifier identifier: String, hasSnapshot: Bool)
    func webView(webView: TLWebView, didRestoreSnapshotForVisitWithIdentifier identifier: String)
    func webView(webView: TLWebView, didStartRequestForVisitWithIdentifier identifier: String)
    func webView(webView: TLWebView, didCompleteRequestForVisitWithIdentifier identifier: String)
    func webView(webView: TLWebView, didFailRequestForVisitWithIdentifier identifier: String, withStatusCode statusCode: Int?)
    func webView(webView: TLWebView, didFinishRequestForVisitWithIdentifier identifier: String)
    func webView(webView: TLWebView, didLoadResponseForVisitWithIdentifier identifier: String)
    func webView(webView: TLWebView, didCompleteVisitWithIdentifier identifier: String)
}

class TLWebView: WKWebView, WKScriptMessageHandler {
    weak var delegate: TLWebViewDelegate?
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

    func visitLocation(location: NSURL, withAction action: String) {
        callJavaScriptFunction("webView.visitLocationWithAction", withArguments: [location.absoluteString, action])
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
            case .VisitProposed:
                delegate?.webView(self, didProposeVisitToLocation: message.location!)
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
                let statusCode = message.data["statusCode"] as? Int
                visitDelegate?.webView(self, didFailRequestForVisitWithIdentifier: message.identifier!, withStatusCode: statusCode)
            case .VisitRequestFinished:
                visitDelegate?.webView(self, didFinishRequestForVisitWithIdentifier: message.identifier!)
            case .VisitResponseLoaded:
                visitDelegate?.webView(self, didLoadResponseForVisitWithIdentifier: message.identifier!)
            case .VisitCompleted:
                visitDelegate?.webView(self, didCompleteVisitWithIdentifier: message.identifier!)
            case .Error:
                let error = message.data["error"] as? String
                NSLog("JavaScript error: \(error)")
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
        if let data = try? NSJSONSerialization.dataWithJSONObject(arguments, options: []),
            string = NSString(data: data, encoding: NSUTF8StringEncoding) as? String {
                return string[Range(start: string.startIndex.successor(), end: string.endIndex.predecessor())]
        }
        return nil
    }
}