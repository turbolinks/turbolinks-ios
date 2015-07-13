import UIKit
import WebKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, SessionDelegate {

    var window: UIWindow?
    var session: Session?
    var navigationController: UINavigationController? {
        return window?.rootViewController as? UINavigationController
    }

    // MARK: UIApplicationDelegate

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        NSUserDefaults.standardUserDefaults().registerDefaults(["UserAgent": "BC3 iOS"])
        
        self.session = Session()
        session!.delegate = self
        session!.visit(NSURL(string: "http://bc3.dev/195539477/")!)
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

    // MARK: SessionDelegate

    func prepareWebViewConfiguration(configuration: WKWebViewConfiguration, forSession session: Session) {
        // ...
    }

    func presentVisitable(visitable: Visitable, forSession session: Session) {
        navigationController?.pushViewController(visitable.viewController, animated: true)
    }
    
    func visitableForLocation(location: NSURL, session: Session) -> Visitable {
        let visitable = WebViewController()
        visitable.location = location
        visitable.visitableDelegate = session
        return visitable
    }
    
    func sessionWillIssueRequest(session: Session) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    func sessionDidFinishRequest(session: Session) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
}
