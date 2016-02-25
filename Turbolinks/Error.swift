import Foundation

public let ErrorDomain = "com.basecamp.Turbolinks"

public enum ErrorCode: Int {
    case HTTPFailure
    case NetworkFailure
}

class Error: NSError {
    init(code: ErrorCode, localizedDescription: String) {
        super.init(domain: ErrorDomain, code: code.rawValue, userInfo: [NSLocalizedDescriptionKey: localizedDescription])
    }
   
    init(code: ErrorCode, statusCode: Int) {
        super.init(domain: ErrorDomain, code: code.rawValue, userInfo: ["statusCode": statusCode, NSLocalizedDescriptionKey: "HTTP Error: \(statusCode)"])
    }

    init(code: ErrorCode, error: NSError) {
        super.init(domain: ErrorDomain, code: code.rawValue, userInfo: ["error": error, NSLocalizedDescriptionKey: error.localizedDescription])
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
