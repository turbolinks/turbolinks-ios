import UIKit
import WebKit

@objc public protocol VisitableDelegate: class {
    func visitableViewWillAppear(visitable: Visitable)
    func visitableViewDidAppear(visitable: Visitable)
    func visitableDidRequestRefresh(visitable: Visitable)
}

@objc public protocol Visitable: class {
    weak var visitableDelegate: VisitableDelegate? { get set }

    var visitableURL: NSURL? { get set }
    var visitableViewController: UIViewController { get }

    func activateVisitableWebView(webView: WKWebView)
    func deactivateVisitableWebView()

    func showVisitableActivityIndicator()
    func hideVisitableActivityIndicator()

    func updateVisitableScreenshot()
    func showVisitableScreenshot()
    func hideVisitableScreenshot()

    func visitableWillRefresh()
    func visitableDidRefresh()

    optional func visitableDidRender()
}
