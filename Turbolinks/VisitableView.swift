import WebKit

public class VisitableView: UIView {
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    private func initialize() {
        installHiddenScrollView()
        installActivityIndicatorView()
    }


    // MARK: Web View

    public var webView: WKWebView?
    private weak var visitable: Visitable?

    public func activateWebView(_ webView: WKWebView, forVisitable visitable: Visitable) {
        self.webView = webView
        self.visitable = visitable
        addSubview(webView)
        addFillConstraintsForSubview(webView)
        updateWebViewScrollViewInsets()
        installRefreshControl()
        showOrHideWebView()
    }

    public func deactivateWebView() {
        removeRefreshControl()
        webView?.removeFromSuperview()
        webView = nil
        visitable = nil
    }

    private func showOrHideWebView() {
        webView?.isHidden = isShowingScreenshot
    }


    // MARK: Refresh Control

    public lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        return refreshControl
    }()

    public var allowsPullToRefresh: Bool = true {
        didSet {
            if allowsPullToRefresh {
                installRefreshControl()
            } else {
                removeRefreshControl()
            }
        }
    }

    public var isRefreshing: Bool {
        return refreshControl.isRefreshing
    }

    private func installRefreshControl() {
        if let scrollView = webView?.scrollView where allowsPullToRefresh {
            scrollView.addSubview(refreshControl)
        }
    }

    private func removeRefreshControl() {
        refreshControl.endRefreshing()
        refreshControl.removeFromSuperview()
    }

    func refresh(_ sender: AnyObject) {
        visitable?.visitableViewDidRequestRefresh()
    }


    // MARK: Activity Indicator

    public lazy var activityIndicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(activityIndicatorStyle: .white)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.color = UIColor.gray()
        view.hidesWhenStopped = true
        return view
    }()

    private func installActivityIndicatorView() {
        addSubview(activityIndicatorView)
        addFillConstraintsForSubview(activityIndicatorView)
    }

    public func showActivityIndicator() {
        if !isRefreshing {
            activityIndicatorView.startAnimating()
            bringSubview(toFront: activityIndicatorView)
        }
    }

    public func hideActivityIndicator() {
        activityIndicatorView.stopAnimating()
    }


    // MARK: Screenshots

    private lazy var screenshotContainerView: UIView = {
        let view = UIView(frame: CGRect.zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = self.backgroundColor
        return view
    }()
    
    private var screenshotView: UIView?

    var isShowingScreenshot: Bool {
        return screenshotContainerView.superview != nil
    }

    public func updateScreenshot() {
        if let webView = self.webView where !isShowingScreenshot {
            screenshotView?.removeFromSuperview()
            
            guard let screenshot = webView.snapshotView(afterScreenUpdates: false) else { return }
            screenshot.translatesAutoresizingMaskIntoConstraints = false
            screenshotContainerView.addSubview(screenshot)

            screenshotContainerView.addConstraints([
                NSLayoutConstraint(item: screenshot, attribute: .centerX, relatedBy: .equal, toItem: screenshotContainerView, attribute: .centerX, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: screenshot, attribute: .top, relatedBy: .equal, toItem: screenshotContainerView, attribute: .top, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: screenshot, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: screenshot.bounds.size.width),
                NSLayoutConstraint(item: screenshot, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: screenshot.bounds.size.height)
                ])

            screenshotView = screenshot
        }
    }
    
    public func showScreenshot() {
        if !isShowingScreenshot && !isRefreshing {
            addSubview(screenshotContainerView)
            addFillConstraintsForSubview(screenshotContainerView)
            showOrHideWebView()
        }
    }

    public func hideScreenshot() {
        screenshotContainerView.removeFromSuperview()
        showOrHideWebView()
    }

    public func clearScreenshot() {
        screenshotView?.removeFromSuperview()
    }


    // MARK: Hidden Scroll View

    private var hiddenScrollView: UIScrollView = {
        let scrollView = UIScrollView(frame: CGRect.zero)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.scrollsToTop = false
        return scrollView
    }()

    private func installHiddenScrollView() {
        insertSubview(hiddenScrollView, at: 0)
        addFillConstraintsForSubview(hiddenScrollView)
    }


    // MARK: Layout

    override public func layoutSubviews() {
        super.layoutSubviews()
        updateWebViewScrollViewInsets()
    }

    private func updateWebViewScrollViewInsets() {
        let adjustedInsets = hiddenScrollView.contentInset
        if let scrollView = webView?.scrollView where scrollView.contentInset.top != adjustedInsets.top && adjustedInsets.top != 0 && !isRefreshing {
            scrollView.scrollIndicatorInsets = adjustedInsets
            scrollView.contentInset = adjustedInsets
        }
    }

    private func addFillConstraintsForSubview(_ view: UIView) {
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: [], metrics: nil, views: [ "view": view ]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: [], metrics: nil, views: [ "view": view ]))
    }
}
