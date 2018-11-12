import Foundation

public let ErrorDomain = "com.basecamp.Turbolinks"

public enum ErrorCategory: Int {
    case httpFailure
    case networkFailure
    case unknown
}

extension NSError {
    open func getCode() -> Int {
        switch getCategory() {
        case .httpFailure:
            return self.userInfo["statusCode"] as! Int
        case .networkFailure:
            return getDetailedCode()
        default:
            return self.code
        }
    }
    
    func getCategory() -> ErrorCategory {
        return ErrorCategory(rawValue: self.code) ?? .unknown
    }
    
    func getDetailedCode() -> Int {
        guard let wrappedError = self.userInfo["error"] as? NSError else { return -1 }
        return wrappedError.code
    }
    
    convenience init(code: ErrorCategory, localizedDescription: String) {
        self.init(domain: ErrorDomain, code: code.rawValue, userInfo: [NSLocalizedDescriptionKey: localizedDescription])
    }
   
    convenience init(code: ErrorCategory, statusCode: Int) {
        self.init(domain: ErrorDomain, code: code.rawValue, userInfo: ["statusCode": statusCode, NSLocalizedDescriptionKey: "HTTP Error: \(statusCode)"])
    }

    convenience init(code: ErrorCategory, error: NSError) {
        self.init(domain: ErrorDomain, code: code.rawValue, userInfo: ["error": error, NSLocalizedDescriptionKey: error.localizedDescription])
    }
}
