import WebKit

enum ScriptMessageName: String {
    case PageLoaded = "pageLoaded"
    case ErrorRaised = "errorRaised"
    case VisitProposed = "visitProposed"
    case VisitStarted = "visitStarted"
    case VisitRequestStarted = "visitRequestStarted"
    case VisitRequestCompleted = "visitRequestCompleted"
    case VisitRequestFailed = "visitRequestFailed"
    case VisitRequestFinished = "visitRequestFinished"
    case VisitRendered = "visitRendered"
    case VisitCompleted = "visitCompleted"
    case PageInvalidated = "pageInvalidated"
}

class ScriptMessage {
    static func parse(message: WKScriptMessage) -> ScriptMessage? {
        guard let body = message.body as? [String: AnyObject],
            rawName = body["name"] as? String, name = ScriptMessageName(rawValue: rawName),
            data = body["data"] as? [String: AnyObject] else {
            return nil
        }
        
        return ScriptMessage(name: name, data: data)
    }

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
   
    var location: NSURL? {
        if let locationString = data["location"] as? String {
            return NSURL(string: locationString)
        }
        
        return nil
    }

    var action: Action? {
        if let actionString = data["action"] as? String {
            return Action(rawValue: actionString)
        }
        
        return nil
    }
}
