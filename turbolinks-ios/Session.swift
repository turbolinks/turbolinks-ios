import UIKit
import WebKit

protocol VisitableDelegate {
    func visitableWebViewWillDisappear(visitable: Visitable)
    func visitableWebViewWillAppear(visitable: Visitable)
    func visitableWebViewDidAppear(visitable: Visitable)
}

protocol Visitable {
    var visitableDelegate: VisitableDelegate? { get set }
    var hasScreenshot: Bool { get }
    var location: NSURL? { get set }
    var viewController: UIViewController { get }

    func activateWebView(webView: WKWebView)
    func deactivateWebView()
    func showLoadingIndicator()
    func hideLoadingIndicator()
    func updateScreenshot()
    func showScreenshot()
    func hideScreenshot()
}

protocol SessionDelegate {
    func prepareWebViewConfiguration(configuration: WKWebViewConfiguration, forSession session: Session)
    func visitableForSession(session: Session, location: NSURL) -> Visitable
}

class Session: NSObject, WKNavigationDelegate, WKScriptMessageHandler, VisitableDelegate {
    var delegate: SessionDelegate?
    var navigationController: UINavigationController?
    var location: NSURL?
    var activeSessionTask: NSURLSessionTask?

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

    func visit(location: NSURL) {
        self.location = location
        if let visitable = delegate?.visitableForSession(self, location: location) {
            pushVisitable(visitable)
            issueRequestForURL(location)
        }
    }

    func pushVisitable(visitable: Visitable) {
        if let navigationController = self.navigationController {
            visitable.activateWebView(webView)
            navigationController.pushViewController(visitable.viewController, animated: true)
        }
    }
    
    func issueRequestForURL(location: NSURL) {
        let request = NSURLRequest(URL: location)

        if webView.URL == nil {
            webView.loadRequest(request)
        } else {
            loadRequest(request)
        }
    }

    // MARK: WKScriptMessageHandler

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if let body = message.body as? [String: AnyObject],
            name = body["name"] as? String,
            data = body["data"] as? String {
                switch name {
                case "visitLocation":
                    if let location = NSURL(string: data) {
                        visit(location)
                    }
                default:
                    println("Unhandled message: \(name): \(data)")
                }
        }
    }

    // MARK: VisitableDelegate

    func visitableWebViewWillDisappear(visitable: Visitable) {
    }

    func visitableWebViewWillAppear(visitable: Visitable) {
    }

    func visitableWebViewDidAppear(visitable: Visitable) {
    }

    // MARK: Private

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

    }
}
