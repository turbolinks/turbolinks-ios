import WebKit

public class TurbolinksView: UIView {
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
        showOrHideWebView()
    }

    public func deactivateWebView() {
        webView?.removeFromSuperview()
        webView = nil
    }

    func showOrHideWebView() {
        webView?.hidden = showingScreenshot
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
        if !showingScreenshot {
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
        if let scrollView = webView?.scrollView where scrollView.contentInset.top != adjustedInsets.top && adjustedInsets.top != 0 {
            scrollView.scrollIndicatorInsets = adjustedInsets
            scrollView.contentInset = adjustedInsets
        }
    }

    func addFillConstraintsForSubview(view: UIView) {
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: [], metrics: nil, views: [ "view": view ]))
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: [], metrics: nil, views: [ "view": view ]))
    }
}