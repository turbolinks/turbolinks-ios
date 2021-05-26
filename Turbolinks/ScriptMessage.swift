import WebKit

enum ScriptMessageName: String {
    case pageLoaded = "pageLoaded"
    case errorRaised = "errorRaised"
    case visitProposed = "visitProposed"
    case visitStarted = "visitStarted"
    case visitRequestStarted = "visitRequestStarted"
    case visitRequestCompleted = "visitRequestCompleted"
    case visitRequestFailed = "visitRequestFailed"
    case visitRequestFinished = "visitRequestFinished"
    case visitRendered = "visitRendered"
    case visitCompleted = "visitCompleted"
    case pageInvalidated = "pageInvalidated"
}

class ScriptMessage {
    let name: ScriptMessageName
    let data: [String: AnyObject]

    init(name: ScriptMessageName, data: [String: AnyObject]) {
        self.name = name
        self.data = data
    }

    var identifier: String? {
        return data["identifier"] as? String
    }

    var restorationIdentifier: String? {
        return data["restorationIdentifier"] as? String
    }
   
    var location: URL? {
        if let locationString = data["location"] as? String {
            return URL(string: locationString)
        }
        
        return nil
    }

    var action: Action? {
        if let actionString = data["action"] as? String {
            return Action(rawValue: actionString)
        }
        
        return nil
    }
    
    static func parse(_ message: WKScriptMessage) -> ScriptMessage? {
        guard let body = message.body as? [String: AnyObject],
            let rawName = body["name"] as? String, let name = ScriptMessageName(rawValue: rawName),
            let data = body["data"] as? [String: AnyObject] else { return nil }
        return ScriptMessage(name: name, data: data)
    }
}
