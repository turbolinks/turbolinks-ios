import WebKit

public class VisitableViewController: UIViewController, Visitable {
    public weak var visitableDelegate: VisitableDelegate?

    public var visitableURL: NSURL!

    public func visitableDidRender() {
        title = visitableView.webView?.title
    }


    // MARK: Visitable View

    public lazy var visitableView: VisitableView = {
        let view = VisitableView(frame: CGRectZero)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private func installVisitableView() {
        view.addSubview(visitableView)
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: [], metrics: nil, views: [ "view": visitableView ]))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: [], metrics: nil, views: [ "view": visitableView ]))
    }


    // MARK: View Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
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
