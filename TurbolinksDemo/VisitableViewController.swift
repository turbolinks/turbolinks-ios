import WebKit
import Turbolinks

class VisitableViewController: UIViewController, Visitable, VisitableViewDelegate {
    weak var visitableDelegate: VisitableDelegate?

    var visitableURL: NSURL?
    
    func activateVisitableWebView(webView: WKWebView) {
        visitableView.activateWebView(webView)
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

    func visitableDidRender() {
        title = visitableView.webView?.title
    }

    func visitableWillRefresh() {
        visitableView.refreshControl.beginRefreshing()
    }

    func visitableDidRefresh() {
        visitableView.refreshControl.endRefreshing()
    }


    // MARK: Visitable View Delegate

    func visitableViewDidRequestRefresh(visitableView: VisitableView) {
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

    override func viewDidLoad() {
        super.viewDidLoad()
        automaticallyAdjustsScrollViewInsets = true
        view.backgroundColor = UIColor.whiteColor()
        installVisitableView()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        visitableDelegate?.visitableViewWillAppear(self)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        visitableDelegate?.visitableViewDidAppear(self)
    }
}
