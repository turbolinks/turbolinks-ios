import WebKit
import Turbolinks

class TurbolinksViewController: UIViewController, Visitable {
    weak var visitableDelegate: VisitableDelegate?

    var visitableURL: NSURL?


    // MARK: Visitable

    func activateVisitableWebView(webView: WKWebView) {
        turbolinksView.activateWebView(webView)
    }

    func deactivateVisitableWebView() {
        turbolinksView.deactivateWebView()
    }

    func showVisitableActivityIndicator() {

    }

    func hideVisitableActivityIndicator() {

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


    // MARK: Turbolinks View

    lazy var turbolinksView: TurbolinksView = {
        let view = TurbolinksView(frame: CGRectZero)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    func installTurbolinksView() {
        view.addSubview(turbolinksView)
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: [], metrics: nil, views: [ "view": turbolinksView ]))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: [], metrics: nil, views: [ "view": turbolinksView ]))
    }
}
