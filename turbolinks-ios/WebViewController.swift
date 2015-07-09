import UIKit
import WebKit

class WebViewController: UIViewController, Visitable {
    weak var visitableDelegate: VisitableDelegate?
    var location: NSURL?
    var webView: WKWebView?
    var viewController: UIViewController {
        get { return self }
    }

    var hasScreenshot: Bool {
        get { return false }
    }

    lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        indicator.setTranslatesAutoresizingMaskIntoConstraints(false)
        indicator.color = UIColor.grayColor()
        return indicator
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        edgesForExtendedLayout = .None
        automaticallyAdjustsScrollViewInsets = false

        view.backgroundColor = UIColor.whiteColor()
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
    }

    func deactivateWebView() {
        webView = nil
    }

    // MARK: Loading Indicator

    func showLoadingIndicator() {
        if let webView = self.webView {
            view.addSubview(loadingIndicator)
            view.addConstraint(NSLayoutConstraint(item: loadingIndicator, attribute: .CenterX, relatedBy: .Equal, toItem: view, attribute: .CenterX, multiplier: 1, constant: 0))
            view.addConstraint(NSLayoutConstraint(item: loadingIndicator, attribute: .CenterY, relatedBy: .Equal, toItem: view, attribute: .CenterY, multiplier: 1, constant: 0))
            
            webView.alpha = 0
            loadingIndicator.startAnimating()
        }
    }

    func hideLoadingIndicator() {
        if let webView = self.webView {
            UIView.animateWithDuration(0.2, animations: { () -> Void in
                self.loadingIndicator.alpha = 0
                webView.alpha = 1
            }, completion: { (_) -> Void in
                self.loadingIndicator.removeFromSuperview()
                self.loadingIndicator.alpha = 1
            })
        }
    }

    // MARK: Screenshots

    func updateScreenshot() {
    }

    func showScreenshot() {
    }

    func hideScreenshot() {
    }
}
