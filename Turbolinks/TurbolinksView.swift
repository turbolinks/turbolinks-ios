import WebKit

@objc public protocol TurbolinksViewDelegate {
    optional func turbolinksViewDidRequestRefresh(turbolinksView: TurbolinksView)
}

public class TurbolinksView: UIView {
    public weak var delegate: TurbolinksViewDelegate?
   
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    func initialize() {
        installHiddenScrollView()
    }


    // MARK: Web View

    public var webView: WKWebView?

    public func activateWebView(webView: WKWebView) {
        self.webView = webView
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
    }

    func showOrHideWebView() {
        webView?.hidden = showingScreenshot
    }


    // MARK: Refresh Control

    public lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "requestRefresh", forControlEvents: .ValueChanged)
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

    var refreshing: Bool {
        return refreshControl.refreshing
    }

    func installRefreshControl() {
        if let scrollView = webView?.scrollView where allowsPullToRefresh {
            scrollView.addSubview(refreshControl)
        }
    }

    func removeRefreshControl() {
        refreshControl.endRefreshing()
        refreshControl.removeFromSuperview()
    }

    func requestRefresh() {
        delegate?.turbolinksViewDidRequestRefresh?(self)
    }


    // MARK: Screenshots

    lazy var screenshotView: UIView = {
        let view = UIView(frame: CGRectZero)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    var showingScreenshot: Bool {
        return screenshotView.superview == self
    }

    public func updateScreenshot() {
        if let webView = self.webView where !showingScreenshot {
            screenshotView = webView.snapshotViewAfterScreenUpdates(false)
        }
    }

    public func showScreenshot() {
        if !showingScreenshot && !refreshing {
            addSubview(screenshotView)
            addFillConstraintsForSubview(screenshotView)
            bringSubviewToFront(screenshotView)
            showOrHideWebView()
        }
    }

    public func hideScreenshot() {
        screenshotView.removeFromSuperview()
        showOrHideWebView()
    }


    // MARK: Hidden Scroll View

    var hiddenScrollView: UIScrollView = {
        let scrollView = UIScrollView(frame: CGRectZero)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.scrollsToTop = false
        return scrollView
    }()

    func installHiddenScrollView() {
        insertSubview(hiddenScrollView, atIndex: 0)
        addFillConstraintsForSubview(hiddenScrollView)
    }


    // MARK: Layout

    override public func layoutSubviews() {
        updateWebViewScrollViewInsets()
    }

    func updateWebViewScrollViewInsets() {
        let adjustedInsets = hiddenScrollView.contentInset
        if let scrollView = webView?.scrollView where scrollView.contentInset.top != adjustedInsets.top && adjustedInsets.top != 0 && !refreshing {
            scrollView.scrollIndicatorInsets = adjustedInsets
            scrollView.contentInset = adjustedInsets
        }
    }

    func addFillConstraintsForSubview(view: UIView) {
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: [], metrics: nil, views: [ "view": view ]))
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: [], metrics: nil, views: [ "view": view ]))
    }
}