import WebKit

public class TurbolinksView: UIView {
    // MARK: Web View

    public var webView: WKWebView?

    public func activateWebView(webView: WKWebView) {
        self.webView = webView
        addSubview(webView)
        addFillConstraintsForSubview(webView)
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
            showOrHideWebView()
        }
    }

    public func hideScreenshot() {
        screenshotView.removeFromSuperview()
        showOrHideWebView()
    }


    // MARK: Layout

    func addFillConstraintsForSubview(view: UIView) {
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: [], metrics: nil, views: [ "view": view ]))
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: [], metrics: nil, views: [ "view": view ]))
    }
}