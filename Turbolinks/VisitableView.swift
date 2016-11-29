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
    public var contentInset: UIEdgeInsets? {
        didSet {
            updateContentInsets()
        }
    }
    private weak var visitable: Visitable?

    public func activateWebView(webView: WKWebView, forVisitable visitable: Visitable) {
        self.webView = webView
        self.visitable = visitable
        addSubview(webView)
        addFillConstraintsForSubview(webView)
        updateContentInsets()
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
        webView?.hidden = isShowingScreenshot
    }


    // MARK: Refresh Control

    public lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh(_:)), forControlEvents: .ValueChanged)
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
        return refreshControl.refreshing
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

    func refresh(sender: AnyObject) {
        visitable?.visitableViewDidRequestRefresh()
    }


    // MARK: Activity Indicator

    public lazy var activityIndicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(activityIndicatorStyle: .White)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.color = UIColor.grayColor()
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
            bringSubviewToFront(activityIndicatorView)
        }
    }

    public func hideActivityIndicator() {
        activityIndicatorView.stopAnimating()
    }


    // MARK: Screenshots

    private lazy var screenshotContainerView: UIView = {
        let view = UIView(frame: CGRectZero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = self.backgroundColor
        return view
    }()
    
    private var screenshotView: UIView?

    var isShowingScreenshot: Bool {
        return screenshotContainerView.superview != nil
    }

    public func updateScreenshot() {
        guard let webView = self.webView where !isShowingScreenshot, let screenshot: UIView = webView.snapshotViewAfterScreenUpdates(false) else { return }

        screenshotView?.removeFromSuperview()
        screenshot.translatesAutoresizingMaskIntoConstraints = false
        screenshotContainerView.addSubview(screenshot)
        
        screenshotContainerView.addConstraints([
            NSLayoutConstraint(item: screenshot, attribute: .CenterX, relatedBy: .Equal, toItem: screenshotContainerView, attribute: .CenterX, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: screenshot, attribute: .Top, relatedBy: .Equal, toItem: screenshotContainerView, attribute: .Top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: screenshot, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: screenshot.bounds.size.width),
            NSLayoutConstraint(item: screenshot, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: screenshot.bounds.size.height)
            ])

        screenshotView = screenshot
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
        let scrollView = UIScrollView(frame: CGRectZero)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.scrollsToTop = false
        return scrollView
    }()

    private func installHiddenScrollView() {
        insertSubview(hiddenScrollView, atIndex: 0)
        addFillConstraintsForSubview(hiddenScrollView)
    }


    // MARK: Layout

    override public func layoutSubviews() {
        super.layoutSubviews()
        updateContentInsets()
    }
    
    private func needsUpdateForContentInsets(adjustedInsets: UIEdgeInsets) -> Bool {
        guard let scrollView = webView?.scrollView else { return false }
        return (scrollView.contentInset.top != adjustedInsets.top && adjustedInsets.top != 0) ||
            (scrollView.contentInset.bottom != adjustedInsets.bottom && adjustedInsets.bottom != 0)
    }
    
    private func updateWebViewScrollViewInsets(adjustedInsets: UIEdgeInsets) {
        if let scrollView = webView?.scrollView where needsUpdateForContentInsets(adjustedInsets) && !isRefreshing {
            scrollView.scrollIndicatorInsets = adjustedInsets
            scrollView.contentInset = adjustedInsets
        }
    }

    private func updateContentInsets() {
        updateWebViewScrollViewInsets(contentInset ?? hiddenScrollView.contentInset)
    }

    private func addFillConstraintsForSubview(view: UIView) {
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: [], metrics: nil, views: [ "view": view ]))
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: [], metrics: nil, views: [ "view": view ]))
    }
}
