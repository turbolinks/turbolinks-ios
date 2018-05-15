//
//  Copyright © 2018 Basecamp. All rights reserved.
//

import WebKit

extension WKWebViewConfiguration {
    func customizeTurbolinksAjaxRequests(withHeaders headers: HTTPHeaders?) {
        guard let headers = headers else { return }
        
        let headersContent = headers.map {
            return "event.data.xhr.setRequestHeader('\($0)', '\($1)');"
        }.joined()
        
        let scriptContent = """
            document.addEventListener("turbolinks:request-start", function(event) { \(headersContent) });
        """
        
        let script = WKUserScript(source: scriptContent, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        
        userContentController.addUserScript(script)
    }
}
