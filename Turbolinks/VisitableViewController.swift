import WebKit

public class VisitableViewController: UIViewController, Visitable, VisitableViewDelegate {
    public weak var visitableDelegate: VisitableDelegate?

    public var visitableURL: NSURL?

    public func activateVisitableWebView(webView: WKWebView) {
        visitableView.activateWebView(webView)
    }

    public func deactivateVisitableWebView() {
        visitableView.deactivateWebView()
    }

    public func showVisitableActivityIndicator() {
        visitableView.showActivityIndicator()
    }

    public func hideVisitableActivityIndicator() {
        visitableView.hideActivityIndicator()
    }

    public func updateVisitableScreenshot() {
        visitableView.updateScreenshot()
    }

    public func showVisitableScreenshot() {
        visitableView.showScreenshot()
    }

    public func hideVisitableScreenshot() {
        visitableView.hideScreenshot()
    }

    public func visitableDidRender() {
        title = visitableView.webView?.title
    }

    public func visitableWillRefresh() {
        visitableView.refreshControl.beginRefreshing()
    }

    public func visitableDidRefresh() {
        visitableView.refreshControl.endRefreshing()
    }


    // MARK: Visitable View Delegate

    public func visitableViewDidRequestRefresh(visitableView: VisitableView) {
        visitableDelegate?.visitableDidRequestRefresh(self)
    }


    // MARK: Visitable View

    lazy var visitableView: VisitableView = {
        let view = VisitableView(frame: CGRectZero)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    func installVisitableView() {
        visitableView.delegate = self
        view.addSubview(visitableView)
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: [], metrics: nil, views: [ "view": visitableView ]))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: [], metrics: nil, views: [ "view": visitableView ]))
    }


    // MARK: View Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        automaticallyAdjustsScrollViewInsets = true
        view.backgroundColor = UIColor.whiteColor()
        installVisitableView()
    }

    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        visitableDelegate?.visitableViewWillAppear(self)
    }

    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        visitableDelegate?.visitableViewDidAppear(self)
    }
}
