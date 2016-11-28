import UIKit

open class VisitableViewController: UIViewController, Visitable {
    open weak var visitableDelegate: VisitableDelegate?

    open var visitableURL: URL!

    public convenience init(url: URL) {
        self.init()
        self.visitableURL = url
    }

    // MARK: Visitable View

    open private(set) lazy var visitableView: VisitableView! = {
        let view = VisitableView(frame: CGRect.zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    fileprivate func installVisitableView() {
        view.addSubview(visitableView)
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: [], metrics: nil, views: [ "view": visitableView ]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: [], metrics: nil, views: [ "view": visitableView ]))
    }

    // MARK: Visitable

    open func visitableDidRender() {
        self.title = visitableView.webView?.title
    }

    // MARK: View Lifecycle

    open override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        installVisitableView()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        visitableDelegate?.visitableViewWillAppear(self)
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        visitableDelegate?.visitableViewDidAppear(self)
    }
}
