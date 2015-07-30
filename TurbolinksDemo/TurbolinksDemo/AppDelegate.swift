import UIKit
import WebKit
import Turbolinks

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, WKNavigationDelegate, TLSessionDelegate, AuthenticationControllerDelegate {
    let userAgent = "BC3 iOS"
    let accountLocation = NSURL(string: "http://bc3.dev/195539477/")!
    let webViewProcessPool = WKProcessPool()

    var window: UIWindow?
    
    var application: UIApplication {
        return UIApplication.sharedApplication()
    }

    var bundle: NSBundle {
        return NSBundle.mainBundle()
    }
    
    var navigationController: UINavigationController? {
        return window?.rootViewController as? UINavigationController
    }

    var session: TLSession?

    // MARK: UIApplicationDelegate

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        NSUserDefaults.standardUserDefaults().registerDefaults(["UserAgent": userAgent])

        let session = TLSession()
        session.delegate = self
        presentVisitableForSession(session, atLocation: accountLocation)
        self.session = session
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    // MARK: Turbolinks
    
    private func presentVisitableForSession(session: TLSession, atLocation location: NSURL) {
        let visitable = visitableForSession(session, atLocation: location)
        navigationController?.pushViewController(visitable.viewController, animated: true)
        session.visitVisitable(visitable)
    }
    
    private func visitableForSession(session: TLSession, atLocation location: NSURL) -> TLVisitable {
        let visitable = WebViewController()
        visitable.location = location
        visitable.visitableDelegate = session
        return visitable
    }
    
    // MARK: TLSessionDelegate

    func prepareWebViewConfiguration(configuration: WKWebViewConfiguration, forSession session: TLSession) {
        let source = String(contentsOfURL: bundle.URLForResource("TurbolinksDemo", withExtension: "js")!, encoding: NSUTF8StringEncoding, error: nil)!
        let userScript = WKUserScript(source: source, injectionTime: .AtDocumentEnd, forMainFrameOnly: true)
        configuration.userContentController.addUserScript(userScript)
        configuration.processPool = webViewProcessPool
    }
    
    func session(session: TLSession, didRequestVisitForLocation location: NSURL) {
        presentVisitableForSession(session, atLocation: location)
    }
    
    func sessionWillIssueRequest(session: TLSession) {
        application.networkActivityIndicatorVisible = true
    }

    func session(session: TLSession, didFailRequestForVisitable visitable: TLVisitable, withError error: NSError) {
        println("REQUEST ERROR: \(error)")
    }

    func session(session: TLSession, didFailRequestForVisitable visitable: TLVisitable, withStatusCode statusCode: Int) {
        println("RECEIVED ERROR RESPONSE: \(statusCode)")

        if statusCode == 401 {
            if let navigationController = self.navigationController {
                let authenticationController = AuthenticationController()
                authenticationController.delegate = self
                authenticationController.accountLocation = accountLocation

                navigationController.presentViewController(authenticationController, animated: true) {
                    // TODO: recreate the navigation controller instead
                    navigationController.viewControllers = []
                }
            }
        }
    }

    func sessionDidFinishRequest(session: TLSession) {
        application.networkActivityIndicatorVisible = false
    }

    func session(session: TLSession, didInitializeWebView webView: WKWebView) {
        webView.navigationDelegate = self
    }
    
    // MARK: AuthenticationControllerDelegate

    func prepareWebViewConfiguration(configuration: WKWebViewConfiguration, forAuthenticationController authenticationController: AuthenticationController) {
        configuration.processPool = webViewProcessPool
    }

    func authenticationControllerDidAuthenticate(authenticationController: AuthenticationController) {
        if let navigationController = self.navigationController {
            let session = TLSession()
            session.delegate = self
            presentVisitableForSession(session, atLocation: accountLocation)
            self.session = session

            navigationController.dismissViewControllerAnimated(true, completion: nil)
        }
    }

    // MARK: WKNavigationDelegate
    
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> ()) {
        decisionHandler(WKNavigationActionPolicy.Cancel)
    }
}
