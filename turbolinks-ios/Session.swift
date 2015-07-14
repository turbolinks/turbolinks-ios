import UIKit
import WebKit

protocol SessionDelegate: class {
    func prepareWebViewConfiguration(configuration: WKWebViewConfiguration, forSession session: Session)
    func presentVisitable(visitable: Visitable, forSession session: Session)
    func visitableForLocation(location: NSURL, session: Session) -> Visitable
    func requestForLocation(location: NSURL) -> NSURLRequest
    func sessionWillIssueRequest(session: Session)
    func sessionDidFinishRequest(session: Session)
}

class Session: NSObject, WKScriptMessageHandler, VisitDelegate, VisitableDelegate {
    weak var delegate: SessionDelegate?

    var initialized: Bool = false
    var location: NSURL?
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

        return webView
    }()
    
    // MARK: Visiting

    private var visit: Visit?
    
    func visit(location: NSURL) {
        if let visitable = delegate?.visitableForLocation(location, session: self) {
            if presentVisitable(visitable) {
                issueVisitForVisitable(visitable)
            }
        }
    }
    
    private func presentVisitable(visitable: Visitable) -> Bool {
        if let delegate = self.delegate {
            delegate.presentVisitable(visitable, forSession: self)
            return true
        } else {
            return false
        }
    }
    
    private func issueVisitForVisitable(visitable: Visitable) {
        if let location = visitable.location {
            let visit: Visit
            let request = requestForLocation(location)
            
            if initialized {
                visit = TurbolinksVisit(visitable: visitable, request: request)
            } else {
                visit = WebViewVisit(visitable: visitable, request: request, webView: webView)
            }
            
            self.visit = visit
            visit.delegate = self
            visit.startRequest()
        }
    }
    
    private func requestForLocation(location: NSURL) -> NSURLRequest {
        return delegate?.requestForLocation(location) ?? NSURLRequest(URL: location)
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

    private func locationChanged(location: NSURL) {
        if let visit = self.visit {
            visit.completeNavigation()
        }
    }
    
    // MARK: VisitDelegate
    
    func visitWillIssueRequest(visit: Visit) {
        delegate?.sessionWillIssueRequest(self)
    }
    
    func visitDidFinishRequest(visit: Visit) {
        delegate?.sessionDidFinishRequest(self)
    }

    func visit(visit: Visit, didCompleteWithResponse response: String) {
        loadResponse(response)
    }
    
    func visitDidCompleteWebViewLoad(visit: Visit) {
        self.initialized = true
    }
   
    func visitDidStart(visit: Visit) {
        let visitable = visit.visitable
        visitable.showScreenshot()
        visitable.showActivityIndicator()
    }
    
    func visitDidFinish(visit: Visit) {
        let visitable = visit.visitable
        visitable.hideScreenshot()
        visitable.hideActivityIndicator()
        self.visit = nil
    }
   
    // MARK: VisitableDelegate

    func visitableViewWillDisappear(visitable: Visitable) {
        visitable.updateScreenshot()
    }

    func visitableViewWillAppear(visitable: Visitable) {
        if let activeVisitable = self.activeVisitable {
            if activeVisitable === visitable {
                visit?.cancelNavigation()
            } else if visit == nil {
                issueVisitForVisitable(visitable)
            }
        }
    }
    
    func visitableViewDidDisappear(visitable: Visitable) {
        deactivateVisitable(visitable)
    }

    func visitableViewDidAppear(visitable: Visitable) {
        if let location = visitable.location {
            activateVisitable(visitable)
            pushLocation(location)
        }
    }

    private func activateVisitable(visitable: Visitable) {
        self.activeVisitable = visitable
        visitable.activateWebView(webView)
    }
    
    private func deactivateVisitable(visitable: Visitable) {
        visitable.deactivateWebView()
    }
    
    private func pushLocation(location: NSURL) {
        let locationJSON = JSONStringify(location.absoluteString!)
        webView.evaluateJavaScript("Turbolinks.controller.history.push(\(locationJSON))", completionHandler: nil)
    }

    // MARK: Request/Response Cycle

    private func loadResponse(response: String) {
        let responseJSON = JSONStringify(response)
        webView.evaluateJavaScript("Turbolinks.controller.loadResponse(\(responseJSON))", completionHandler: { (result, error) -> () in
            after(100) {
                visit?.finish()
            }
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

func after(msec: Int, callback: () -> ()) {
    let time = dispatch_time(DISPATCH_TIME_NOW, (Int64)(100 * NSEC_PER_MSEC))
    dispatch_after(time, dispatch_get_main_queue(), callback)
}
