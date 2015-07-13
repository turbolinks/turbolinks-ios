import UIKit
import WebKit

protocol VisitableDelegate: class {
    func visitableWebViewWillDisappear(visitable: Visitable)
    func visitableWebViewDidDisappear(visitable: Visitable)
    func visitableWebViewWillAppear(visitable: Visitable)
    func visitableWebViewDidAppear(visitable: Visitable)
}

protocol Visitable: class {
    weak var visitableDelegate: VisitableDelegate? { get set }
    var location: NSURL? { get set }
    var viewController: UIViewController { get }
    
    func activateWebView(webView: WKWebView)
    func deactivateWebView()
    func showActivityIndicator()
    func hideActivityIndicator()
    func updateScreenshot()
    func showScreenshot()
    func hideScreenshot()
}
