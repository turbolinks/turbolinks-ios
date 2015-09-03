import WebKit

enum TLScriptMessageName: String {
    case VisitRequested = "visitRequested"
    case LocationChanged = "locationChanged"
    case SnapshotRestored = "snapshotRestored"
    case RequestCompleted = "requestCompleted"
    case RequestFailed = "requestFailed"
    case ResponseLoaded = "responseLoaded"
    case PageInvalidated = "pageInvalidated"
}

protocol TLWebViewDelegate: class {
    func webView(webView: TLWebView, didRequestVisitToLocation location: NSURL)
    func webView(webView: TLWebView, didNavigateToLocation location: NSURL)
    func webView(webView: TLWebView, didRestoreSnapshotForLocation location: NSURL)
    func webView(webView: TLWebView, didLoadResponseForLocation location: NSURL)
    func webViewDidInvalidatePage(webView: TLWebView)
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
        callJavaScriptFunction("webView.hasSnapshotForLocation", withArguments: [location.absoluteString!]) { (result) -> () in
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
        if let (name: TLScriptMessageName, data: AnyObject?) = parseScriptMessage(message) {
            var location: NSURL? = locationFromScriptMessageData(data)

            switch name {
            case .VisitRequested:
                delegate?.webView(self, didRequestVisitToLocation: location!)
            case .LocationChanged:
                delegate?.webView(self, didNavigateToLocation: location!)
            case .SnapshotRestored:
                delegate?.webView(self, didRestoreSnapshotForLocation: location!)
            case .RequestCompleted:
                let response = data as! String
                requestDelegate?.webView(self, didReceiveResponse: response)
            case .RequestFailed:
                let statusCode = data as? Int
                requestDelegate?.webView(self, requestDidFailWithStatusCode: statusCode)
            case .ResponseLoaded:
                delegate?.webView(self, didLoadResponseForLocation: location!)
            case .PageInvalidated:
                delegate?.webViewDidInvalidatePage(self)
            }
        }
    }

    private func parseScriptMessage(message: WKScriptMessage) -> (name: TLScriptMessageName, data: AnyObject?)? {
        if let dictionary = message.body as? [String: AnyObject] {
            if let rawName = dictionary["name"] as? String, data: AnyObject? = dictionary["data"] {
                if let name = TLScriptMessageName(rawValue: rawName) {
                    return (name, data)
                }
            }
        }
        return nil
    }

    private func locationFromScriptMessageData(data: AnyObject?) -> NSURL? {
        if let string = data as? String, location = NSURL(string: string) {
            return location
        }
        return nil
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