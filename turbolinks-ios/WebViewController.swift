import UIKit
import WebKit

class WebViewController: UIViewController, Visitable {
    weak var visitableDelegate: VisitableDelegate?
    var location: NSURL?
    var webView: WKWebView?
    var viewController: UIViewController { return self }
    var hasScreenshot: Bool { return false }

    override func viewDidLoad() {
        super.viewDidLoad()

        edgesForExtendedLayout = .None
        automaticallyAdjustsScrollViewInsets = false

        view.backgroundColor = UIColor.whiteColor()
        
        insertActivityIndicator()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        visitableDelegate?.visitableWebViewWillDisappear(self)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        visitableDelegate?.visitableWebViewDidDisappear(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        visitableDelegate?.visitableWebViewWillAppear(self)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        visitableDelegate?.visitableWebViewDidAppear(self)
    }

    // MARK: Web View

    func activateWebView(webView: WKWebView) {
        self.webView = webView
        view.addSubview(webView)
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: nil, metrics: nil, views: [ "view": webView ]))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: nil, metrics: nil, views: [ "view": webView ]))
        view.sendSubviewToBack(webView)
    }

    func deactivateWebView() {
        webView = nil
    }

    // MARK: Activity Indicator

    lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        activityIndicator.setTranslatesAutoresizingMaskIntoConstraints(false)
        activityIndicator.color = UIColor.grayColor()
        return activityIndicator
    }()
    
    func showActivityIndicator() {
        activityIndicator.startAnimating()
        view.bringSubviewToFront(activityIndicator)
    }

    func hideActivityIndicator() {
        activityIndicator.stopAnimating()
    }

    private func insertActivityIndicator() {
        view.addSubview(activityIndicator)
        view.addConstraint(NSLayoutConstraint(item: activityIndicator, attribute: .CenterX, relatedBy: .Equal, toItem: view, attribute: .CenterX, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: activityIndicator, attribute: .CenterY, relatedBy: .Equal, toItem: view, attribute: .CenterY, multiplier: 1, constant: 0))
    }
   
    // MARK: Screenshots

    func updateScreenshot() {
    }

    func showScreenshot() {
    }

    func hideScreenshot() {
    }
}
