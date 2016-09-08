import Foundation

public let ErrorDomain = "com.basecamp.Turbolinks"

public enum ErrorCode: Int {
    case httpFailure
    case networkFailure
}

extension NSError {
    convenience init(code: ErrorCode, localizedDescription: String) {
        self.init(domain: ErrorDomain, code: code.rawValue, userInfo: [NSLocalizedDescriptionKey: localizedDescription])
    }
   
    convenience init(code: ErrorCode, statusCode: Int) {
        self.init(domain: ErrorDomain, code: code.rawValue, userInfo: ["statusCode": statusCode, NSLocalizedDescriptionKey: "HTTP Error: \(statusCode)"])
    }

    convenience init(code: ErrorCode, error: NSError) {
        self.init(domain: ErrorDomain, code: code.rawValue, userInfo: ["error": error, NSLocalizedDescriptionKey: error.localizedDescription])
    }
}
