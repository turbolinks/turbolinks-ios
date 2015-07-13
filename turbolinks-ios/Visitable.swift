import UIKit
import WebKit

protocol VisitableDelegate: class {
    func visitableViewWillDisappear(visitable: Visitable)
    func visitableViewDidDisappear(visitable: Visitable)
    func visitableViewWillAppear(visitable: Visitable)
    func visitableViewDidAppear(visitable: Visitable)
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
