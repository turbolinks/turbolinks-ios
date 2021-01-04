import Foundation

extension Bundle {
    static var turbolinks: Bundle {
#if SWIFT_PACKAGE
        return Bundle.module
#else
        return Bundle(for: WebView.self)
#endif
    }
}
