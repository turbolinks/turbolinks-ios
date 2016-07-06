import UIKit

public class VisitableViewController: UIViewController, Visitable {
    public weak var visitableDelegate: VisitableDelegate?

    public var visitableURL: URL!

    public convenience init(url: URL) {
        self.init()
        self.visitableURL = url
    }

    // MARK: Visitable View

    public lazy var visitableView: VisitableView! = {
        let view = VisitableView(frame: CGRect.zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private func installVisitableView() {
        view.addSubview(visitableView)
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: [], metrics: nil, views: [ "view": visitableView ]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: [], metrics: nil, views: [ "view": visitableView ]))
    }

    // MARK: Visitable

    public func visitableDidRender() {
        self.title = visitableView.webView?.title
    }

    // MARK: View Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white()
        installVisitableView()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        visitableDelegate?.visitableViewWillAppear(self)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        visitableDelegate?.visitableViewDidAppear(self)
    }
}
