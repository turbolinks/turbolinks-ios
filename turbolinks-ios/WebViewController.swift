import UIKit
import WebKit

class WebViewController: UIViewController {
    override var navigationController : NavigationController? {
        return super.navigationController as? NavigationController
    }

    lazy var URL: NSURL = {
        return self.navigationController!.rootURL
    }()

    lazy var webView: WKWebView = {
        return self.navigationController!.webView
    }()

    lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        indicator.setTranslatesAutoresizingMaskIntoConstraints(false)
        indicator.color = UIColor.grayColor()
        return indicator
     }()

    private var activeSessionTask: NSURLSessionTask?

    convenience init(URL: NSURL) {
        self.init()
        self.URL = URL
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        edgesForExtendedLayout = .None
        automaticallyAdjustsScrollViewInsets = false

        view.backgroundColor = UIColor.whiteColor()
        webView.backgroundColor = view.backgroundColor
        webView.scrollView.backgroundColor = view.backgroundColor
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        insertWebView()
        showLoadingIndicator()
        performRequest()
    }

    private func insertWebView() {
        view.addSubview(webView)
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: nil, metrics: nil, views: [ "view": webView ]))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: nil, metrics: nil, views: [ "view": webView ]))
    }

    private func performRequest() {
        let request = NSURLRequest(URL: URL)

        if webView.URL == nil {
            webView.loadRequest(request)
        } else {
            // This isn't the right time to call navigateToLocation. We should wait to call it until we know it's the final destination, on viewDidAppear. We should also make sure to only call loadResponse on or after viewDidAppear.
            navigateToLocation(URL)
            loadRequest(request)
        }
    }

    private func loadRequest(request: NSURLRequest) {
        if let sessionTask = activeSessionTask {
            sessionTask.cancel()
        }

        let session = NSURLSession.sharedSession()
        activeSessionTask = session.dataTaskWithRequest(request) { (data, response, error) in
            if let httpResponse = response as? NSHTTPURLResponse
                where httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                    dispatch_async(dispatch_get_main_queue()) {
                        if let response = NSString(data: data, encoding: NSUTF8StringEncoding) as? String {
                            self.loadResponse(response)
                        }
                    }
            }
        }

        activeSessionTask?.resume()
    }

    private func loadResponse(response: String) {
        let serializedResponse = JSONStringify(response)
        webView.evaluateJavaScript("Turbolinks.controller.loadResponse(\(serializedResponse))", completionHandler: nil)

        // FIXME: Move this to a more appropriate time. Since JavaScript is processed async,
        // this may not be when the response is actually loaded.
        responseDidLoad()
    }
    
    private func navigateToLocation(location: NSURL) {
        let serializedURL = JSONStringify("\(location)")
        webView.evaluateJavaScript("Turbolinks.controller.history.push(\(serializedURL))", completionHandler: nil)
    }
    
    func responseDidLoad() {
        hideLoadingIndicator()
    }

    // MARK: Loading Indicator

    private func showLoadingIndicator() {
        view.addSubview(loadingIndicator)
        view.addConstraint(NSLayoutConstraint(item: loadingIndicator, attribute: .CenterX, relatedBy: .Equal, toItem: view, attribute: .CenterX, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: loadingIndicator, attribute: .CenterY, relatedBy: .Equal, toItem: view, attribute: .CenterY, multiplier: 1, constant: 0))

        webView.alpha = 0
        loadingIndicator.startAnimating()
    }

    private func hideLoadingIndicator() {
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.loadingIndicator.alpha = 0
            self.webView.alpha = 1
        }, completion: { (_) -> Void in
            self.loadingIndicator.removeFromSuperview()
            self.loadingIndicator.alpha = 1
        })
    }
}

func JSONStringify(object: AnyObject) -> String {
    if let data = NSJSONSerialization.dataWithJSONObject([object], options: nil, error: nil),
        string = NSString(data: data, encoding: NSUTF8StringEncoding) as? String {
            return string[Range(start: string.startIndex.successor(), end: string.endIndex.predecessor())]
    } else {
        return "null"
    }
}
