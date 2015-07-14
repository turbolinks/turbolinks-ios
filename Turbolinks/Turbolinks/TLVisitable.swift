import UIKit
import WebKit

public protocol TLVisitableDelegate: class {
    func visitableViewWillDisappear(visitable: TLVisitable)
    func visitableViewDidDisappear(visitable: TLVisitable)
    func visitableViewWillAppear(visitable: TLVisitable)
    func visitableViewDidAppear(visitable: TLVisitable)
}

public protocol TLVisitable: class {
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
}
