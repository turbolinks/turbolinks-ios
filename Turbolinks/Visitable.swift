import UIKit
import WebKit

@objc public protocol VisitableDelegate: class {
    func visitableViewWillAppear(visitable: Visitable)
    func visitableViewDidAppear(visitable: Visitable)
    func visitableDidRequestRefresh(visitable: Visitable)
}

@objc public protocol Visitable: class {
    weak var visitableDelegate: VisitableDelegate? { get set }

    var URL: NSURL? { get set }
    var viewController: UIViewController { get }

    func activateWebView(webView: WKWebView)
    func deactivateWebView()

    func showActivityIndicator()
    func hideActivityIndicator()

    func updateScreenshot()
    func showScreenshot()
    func hideScreenshot()

    func willRefresh()
    func didRefresh()

    optional func didRender()
}
