import UIKit
import WebKit

@objc public protocol VisitableDelegate: class {
    func visitableViewWillAppear(visitable: Visitable)
    func visitableViewDidAppear(visitable: Visitable)
    func visitableDidRequestRefresh(visitable: Visitable)
}

@objc public protocol Visitable: class {
    weak var visitableDelegate: VisitableDelegate? { get set }
    var visitableURL: NSURL! { get }
    var visitableView: VisitableView! { get }
    optional func visitableDidRender()
}

extension Visitable {
    public var visitableViewController: UIViewController {
        return self as! UIViewController
    }

    func activateVisitableWebView(webView: WKWebView) {
        visitableView.activateWebView(webView, forVisitable: self)
    }

    func deactivateVisitableWebView() {
        visitableView.deactivateWebView()
    }

    func showVisitableActivityIndicator() {
        visitableView.showActivityIndicator()
    }

    func hideVisitableActivityIndicator() {
        visitableView.hideActivityIndicator()
    }

    func updateVisitableScreenshot() {
        visitableView.updateScreenshot()
    }

    func showVisitableScreenshot() {
        visitableView.showScreenshot()
    }

    func hideVisitableScreenshot() {
        visitableView.hideScreenshot()
    }

    func clearVisitableScreenshot() {
        visitableView.clearScreenshot()
    }

    func visitableWillRefresh() {
        visitableView.refreshControl.beginRefreshing()
    }

    func visitableDidRefresh() {
        visitableView.refreshControl.endRefreshing()
    }

    func visitableViewDidRequestRefresh() {
        visitableDelegate?.visitableDidRequestRefresh(self)
    }
}
