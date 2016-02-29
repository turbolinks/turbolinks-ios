import WebKit
import Turbolinks

class TurbolinksViewController: UIViewController, Visitable, TurbolinksViewDelegate {
    weak var visitableDelegate: VisitableDelegate?

    var visitableURL: NSURL?
    
    func activateVisitableWebView(webView: WKWebView) {
        turbolinksView.activateWebView(webView)
    }

    func deactivateVisitableWebView() {
        turbolinksView.deactivateWebView()
    }

    func showVisitableActivityIndicator() {
        turbolinksView.showActivityIndicator()
    }

    func hideVisitableActivityIndicator() {
        turbolinksView.hideActivityIndicator()
    }

    func updateVisitableScreenshot() {
        turbolinksView.updateScreenshot()
    }

    func showVisitableScreenshot() {
        turbolinksView.showScreenshot()
    }

    func hideVisitableScreenshot() {
        turbolinksView.hideScreenshot()
    }

    func visitableDidRender() {
        title = turbolinksView.webView?.title
    }

    func visitableWillRefresh() {
        turbolinksView.refreshControl.beginRefreshing()
    }

    func visitableDidRefresh() {
        turbolinksView.refreshControl.endRefreshing()
    }


    // MARK: Turbolinks View Delegate

    func turbolinksViewDidRequestRefresh(turbolinksView: TurbolinksView) {
        visitableDelegate?.visitableDidRequestRefresh(self)
    }
   

    // MARK: Turbolinks View

    lazy var turbolinksView: TurbolinksView = {
        let view = TurbolinksView(frame: CGRectZero)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    func installTurbolinksView() {
        turbolinksView.delegate = self
        view.addSubview(turbolinksView)
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: [], metrics: nil, views: [ "view": turbolinksView ]))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: [], metrics: nil, views: [ "view": turbolinksView ]))
    }


    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        automaticallyAdjustsScrollViewInsets = true
        view.backgroundColor = UIColor.whiteColor()
        installTurbolinksView()
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
