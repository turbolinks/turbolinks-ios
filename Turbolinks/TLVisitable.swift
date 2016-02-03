import UIKit
import WebKit

@objc public protocol TLVisitableDelegate: class {
    func visitableViewWillAppear(visitable: TLVisitable)
    func visitableViewDidAppear(visitable: TLVisitable)
    func visitableDidRequestRefresh(visitable: TLVisitable)
}

@objc public protocol TLVisitable: class {
    weak var visitableDelegate: TLVisitableDelegate? { get set }

    var location: NSURL? { get set }
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
