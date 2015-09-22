import Foundation

public let TLErrorDomain = "com.basecamp.Turbolinks"

public enum TLErrorCode: Int {
    case HTTPFailure
    case NetworkFailure
}

class TLError: NSError {
    init(code: TLErrorCode, localizedDescription: String) {
        super.init(domain: TLErrorDomain, code: code.rawValue, userInfo: [NSLocalizedDescriptionKey: localizedDescription])
    }
   
    init(code: TLErrorCode, statusCode: Int) {
        super.init(domain: TLErrorDomain, code: code.rawValue, userInfo: ["statusCode": statusCode, NSLocalizedDescriptionKey: "HTTP Error: \(statusCode)"])
    }

    init(code: TLErrorCode, error: NSError) {
        super.init(domain: TLErrorDomain, code: code.rawValue, userInfo: ["error": error, NSLocalizedDescriptionKey: error.localizedDescription])
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
