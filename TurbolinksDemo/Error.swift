struct Error {
    static let HTTPNotFoundError = Error(title: "Page Not Found", message: "Oh no!")
    static let NetworkError = Error(title: "Can’t Connect", message: "TurbolinksDemo can’t connect to the server. Did you remember to start it?")
    static let UnknownError = Error(title: "Unknown Error", message: "Try again")

    let title: String
    let message: String

    init(title: String, message: String) {
        self.title = title
        self.message = message
    }

    init(statusCode: Int) {
        self.title = "Server Error"
        self.message = "HTTP \(statusCode)"
    }
}