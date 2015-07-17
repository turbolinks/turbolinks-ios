import WebKit

class TLWebView: WKWebView {
    // MARK: JavaScript Evaluation

    func callJavaScriptFunction(functionExpression: String, withArguments arguments: [AnyObject] = [], completionHandler: ((AnyObject?, NSError?) -> ())? = { (_, _) -> () in }) {
        let script = scriptForCallingJavaScriptFunction(functionExpression, withArguments: arguments)
        evaluateJavaScript(script, completionHandler: completionHandler)
    }

    private func scriptForCallingJavaScriptFunction(functionExpression: String, withArguments arguments: [AnyObject]) -> String {
        return functionExpression + "(" + ", ".join(arguments.map(encodeObjectAsJSON)) + ")"
    }

    private func encodeObjectAsJSON(object: AnyObject) -> String {
        if let data = NSJSONSerialization.dataWithJSONObject([object], options: nil, error: nil),
            string = NSString(data: data, encoding: NSUTF8StringEncoding) as? String {
                return string[Range(start: string.startIndex.successor(), end: string.endIndex.predecessor())]
        } else {
            return "null"
        }
    }
}