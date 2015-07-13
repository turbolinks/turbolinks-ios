import UIKit
import WebKit

protocol SessionDelegate: class {
    func prepareWebViewConfiguration(configuration: WKWebViewConfiguration, forSession session: Session)
    func presentVisitable(visitable: Visitable, forSession session: Session)
    func visitableForLocation(location: NSURL, session: Session) -> Visitable
    func sessionWillIssueRequest(session: Session)
    func sessionDidFinishRequest(session: Session)
}

class Session: NSObject, WKNavigationDelegate, WKScriptMessageHandler, VisitableDelegate {
    weak var delegate: SessionDelegate?

    var initialized: Bool = false
    var visiting: Bool = false
    var location: NSURL?
    
    var activeSessionTask: NSURLSessionTask?
    var activeVisitable: Visitable?
    
    lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = WKUserContentController()

        let userScript = NSString(contentsOfURL: NSBundle.mainBundle().URLForResource("app", withExtension: "js")!, encoding: NSUTF8StringEncoding, error: nil)!
        configuration.userContentController.addUserScript(WKUserScript(source: userScript as! String, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: true))
        configuration.userContentController.addScriptMessageHandler(self, name: "turbolinks")

        self.delegate?.prepareWebViewConfiguration(configuration, forSession: self)

        let webView = WKWebView(frame: CGRectZero, configuration: configuration)
        webView.setTranslatesAutoresizingMaskIntoConstraints(false)
        webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal
        webView.navigationDelegate = self

        return webView
    }()

    // MARK: WKNavigationDelegate
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        self.initialized = true
        didFinishRequest()
        didNavigate()
        activeVisitable?.hideActivityIndicator()
        activeVisitable?.hideScreenshot()
    }
   
    // MARK: WKScriptMessageHandler

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if let body = message.body as? [String: AnyObject],
            name = body["name"] as? String,
            data = body["data"] as? String {
                switch name {
                case "visit":
                    if let location = NSURL(string: data) {
                        visit(location)
                    }
                case "locationChanged":
                    if let location = NSURL(string: data) {
                        locationChanged(location)
                    }
                default:
                    println("Unhandled message: \(name): \(data)")
                }
        }
    }

    func visit(location: NSURL) {
        if let visitable = delegate?.visitableForLocation(location, session: self) {
            self.visiting = true

            if presentVisitable(visitable) {
                self.location = location
                willNavigate()
                issueRequestForURL(location)
            } else {
                self.visiting = false
            }
        }
    }

    private func locationChanged(location: NSURL) {
        didNavigate()
    }
    
    private func presentVisitable(visitable: Visitable) -> Bool {
        if let delegate = self.delegate {
            delegate.presentVisitable(visitable, forSession: self)
            return true
        } else {
            return false
        }
    }

    // MARK: VisitableDelegate

    func visitableViewWillDisappear(visitable: Visitable) {
        willNavigate()
        visitable.updateScreenshot()
    }

    func visitableViewDidDisappear(visitable: Visitable) {
        visitable.deactivateWebView()
    }

    func visitableViewWillAppear(visitable: Visitable) {
        if let activeVisitable = self.activeVisitable {
            if activeVisitable === visitable {
                return didCancelNavigation()
            } else if !visiting {
                willNavigateBackwardToVisitable(visitable)
            }
        }

        visitable.showScreenshot()
        visitable.showActivityIndicator()
    }

    func visitableViewDidAppear(visitable: Visitable) {
        self.activeVisitable = visitable
        visitable.activateWebView(webView)
        if let location = visitable.location {
            pushLocation(location)
        }
    }

    private func pushLocation(location: NSURL) {
        let locationJSON = JSONStringify(location.absoluteString!)
        webView.evaluateJavaScript("Turbolinks.controller.history.push(\(locationJSON))", completionHandler: nil)
    }

    private func willNavigateBackwardToVisitable(visitable: Visitable) {
        if let URL = visitable.location {
            let request = NSURLRequest(URL: URL)
            loadRequest(request)
        }
    }

    // MARK: Request/Response Cycle

    private func issueRequestForURL(location: NSURL) {
        let request = NSURLRequest(URL: location)
        willIssueRequest()
        
        if webView.URL == nil {
            webView.loadRequest(request)
        } else {
            loadRequest(request)
        }
    }
    
    private func loadRequest(request: NSURLRequest) {
        activeSessionTask?.cancel()
        
        let session = NSURLSession.sharedSession()
        activeSessionTask = session.dataTaskWithRequest(request) { (data, response, error) in
            if let httpResponse = response as? NSHTTPURLResponse
                where httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                    if let response = NSString(data: data, encoding: NSUTF8StringEncoding) as? String {
                        println("received response")
                        self.afterSuccessfulNavigation() { self.loadResponse(response) }
                    }
            }
            self.didFinishRequest()
        }

        activeSessionTask?.resume()
    }

    private func loadResponse(response: String) {
        let responseJSON = JSONStringify(response)
        webView.evaluateJavaScript("Turbolinks.controller.loadResponse(\(responseJSON))", completionHandler: { (result, error) -> () in
            after(100) {
                if let activeVisitable = self.activeVisitable {
                    activeVisitable.hideScreenshot()
                    activeVisitable.hideActivityIndicator()
                }
            }
        })
    }
    
    private func willIssueRequest() {
        delegate?.sessionWillIssueRequest(self)
    }

    private func didFinishRequest() {
        delegate?.sessionDidFinishRequest(self)
    }
    
    // MARK: Navigation Lifecycle
    
    private var navigating: Bool = false
    private var navigationLock: Lock?

    private func willNavigate() {
        if !navigating {
            self.navigating = true
            createNavigationLock()
        }
    }
    
    private func didCancelNavigation() {
        if navigating {
            self.navigating = false
            destroyNavigationLock()
        }
    }
   
    private func didNavigate() {
        if navigating {
            self.visiting = false
            self.navigating = false
            unlockNavigationLock()
        }
    }
    
    private func createNavigationLock() {
        self.navigationLock = Lock(queue: dispatch_get_main_queue())
    }
    
    private func destroyNavigationLock() {
        self.navigationLock = nil
    }
    
    private func unlockNavigationLock() {
        navigationLock?.unlock()
    }

    private func afterSuccessfulNavigation(completion: () -> ()) {
        navigationLock?.afterUnlock(completion)
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

func after(msec: Int, callback: () -> ()) {
    let time = dispatch_time(DISPATCH_TIME_NOW, (Int64)(100 * NSEC_PER_MSEC))
    dispatch_after(time, dispatch_get_main_queue(), callback)
}
