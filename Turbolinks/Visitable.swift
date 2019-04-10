import UIKit
import WebKit

public protocol VisitableDelegate: class {
    func visitableViewWillAppear(_ visitable: Visitable)
    func visitableViewDidAppear(_ visitable: Visitable)
    func visitableDidRequestReload(_ visitable: Visitable)
    func visitableDidRequestRefresh(_ visitable: Visitable)
}

public protocol Visitable: class {
    var visitableDelegate: VisitableDelegate? { get set } 
    var visitableView: VisitableView! { get }
    var visitableURL: URL! { get set }
    func visitableDidRender()
}

extension Visitable {
    public var visitableViewController: UIViewController {
        return self as! UIViewController
    }

    public func visitableDidRender() {
        visitableViewController.title = visitableView.webView?.title
    }

    public func reloadVisitable() {
        visitableDelegate?.visitableDidRequestReload(self)
    }

    func activateVisitableWebView(_ webView: WKWebView) {
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
