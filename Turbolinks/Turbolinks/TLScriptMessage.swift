import WebKit

enum TLScriptMessageName: String {
    case PageLoaded = "pageLoaded"
    case ErrorRaised = "errorRaised"
    case VisitProposed = "visitProposed"
    case VisitStarted = "visitStarted"
    case VisitSnapshotRestored = "visitSnapshotRestored"
    case VisitRequestStarted = "visitRequestStarted"
    case VisitRequestCompleted = "visitRequestCompleted"
    case VisitRequestFailed = "visitRequestFailed"
    case VisitRequestFinished = "visitRequestFinished"
    case VisitResponseLoaded = "visitResponseLoaded"
    case VisitCompleted = "visitCompleted"
    case PageInvalidated = "pageInvalidated"
}

class TLScriptMessage {
    static func parse(message: WKScriptMessage) -> TLScriptMessage? {
        if let body = message.body as? [String: AnyObject] {
            if let rawName = body["name"] as? String, let data = body["data"] as? [String: AnyObject] {
                if let name = TLScriptMessageName(rawValue: rawName) {
                    return TLScriptMessage(name: name, data: data)
                }
            }
        }
        return nil
    }

    let name: TLScriptMessageName
    let data: [String: AnyObject]

    init(name: TLScriptMessageName, data: [String: AnyObject]) {
        self.name = name
        self.data = data
    }

    var identifier: String? {
        return data["identifier"] as? String
    }
   
    var location: NSURL? {
        if let locationString = data["location"] as? String {
            return NSURL(string: locationString)
        }
        return nil
    }

    var action: TLAction? {
        if let actionString = data["action"] as? String {
            return TLAction(rawValue: actionString)
        }
        return nil
    }
}
