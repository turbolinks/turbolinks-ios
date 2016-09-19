import UIKit

public class VisitableViewController: UIViewController, Visitable {
    public weak var visitableDelegate: VisitableDelegate?

    public var visitableURL: NSURL!

    public convenience init(URL: NSURL) {
        self.init()
        self.visitableURL = URL
    }

    // MARK: Visitable View

    public lazy var visitableView: VisitableView! = {
        let view = VisitableView(frame: CGRectZero)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private func installVisitableView() {
        view.addSubview(visitableView)
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: [], metrics: nil, views: [ "view": visitableView ]))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: [], metrics: nil, views: [ "view": visitableView ]))
    }

    // MARK: Visitable

    public func visitableDidRender() {
        self.title = visitableView.webView?.title
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

    /*
     If the visitableView is a child of the main view, and anchored to its top and bottom, then it's
     unlikely you will need to customize the layout. But more complicated view hierarchies and layout 
     may require explicit control over the contentInset. Below is an example of setting the contentInset 
     to the layout guides.
     
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        visitableView.contentInset = UIEdgeInsets(top: topLayoutGuide.length, left: 0, bottom: bottomLayoutGuide.length, right: 0)
    }
    */
}
