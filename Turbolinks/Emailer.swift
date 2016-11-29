import UIKit
import MessageUI


public class Emailer: NSObject, MFMailComposeViewControllerDelegate {
    
    var mail: MFMailComposeViewController?

    override init() {
        self.mail = MFMailComposeViewController()
    }

    func sendEmail(URL: NSURL) {
        if MFMailComposeViewController.canSendMail() {
            mail?.mailComposeDelegate = self
            setMailAttributesFromUrl(mail!, URL: URL)
            if let controller = UIApplication.sharedApplication().keyWindow?.visibleViewController() {
                controller.navigationController?.presentViewController(mail!, animated: true, completion: nil)
            }
            
        } else {
            // show failure alert
        }
    }
    
    public func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true) { () -> Void in
            self.cycleMailComposer()
        }
    }
    
    func cycleMailComposer() {
        mail = nil
        mail = MFMailComposeViewController()
    }
    
    func setMailAttributesFromUrl(mail: MFMailComposeViewController, URL: NSURL) {
        var rawURLparts: [AnyObject] = URL.resourceSpecifier.componentsSeparatedByString("?")
        if rawURLparts.count > 2 {
            return
            // invalid URL
        }
        
        var toRecipients: [String] = []
        let defaultRecipient = rawURLparts[0]
        if defaultRecipient.length > 0 {
            toRecipients.append((defaultRecipient as! String).stringByRemovingPercentEncoding!)
        }
        
        if rawURLparts.count == 2 {
            let queryString = rawURLparts[1]
            let params = queryString.componentsSeparatedByString("&")
            for param: String in params {
                var keyValue = param.componentsSeparatedByString("=")
                if keyValue.count != 2 {
                    continue
                }
                let key = keyValue[0].lowercaseString
                var value = keyValue[1]
                value = value.stringByRemovingPercentEncoding!
                
                if (key == "subject") {
                    mail.setSubject(value)
                }
                if (key == "body") {
                    mail.setMessageBody(value, isHTML: false)
                }
                if (key == "to") {
                    toRecipients.appendContentsOf(value.componentsSeparatedByString(","))
                }
                if (key == "cc") {
                    let recipients: [String] = value.componentsSeparatedByString(",")
                    mail.setCcRecipients(recipients)
                }
                if (key == "bcc") {
                    let recipients: [String] = value.componentsSeparatedByString(",")
                    mail.setBccRecipients(recipients)
                }
            }
        }
        
        mail.setToRecipients(toRecipients as [String])
    }

}

extension UIWindow {
    
    func visibleViewController() -> UIViewController? {
        if let rootViewController: UIViewController  = self.rootViewController {
            return UIWindow.getVisibleViewControllerFrom(rootViewController)
        }
        return nil
    }
    
    class func getVisibleViewControllerFrom(vc:UIViewController) -> UIViewController {
        
        if vc.isKindOfClass(UINavigationController.self) {
            
            let navigationController = vc as! UINavigationController
            return UIWindow.getVisibleViewControllerFrom( navigationController.visibleViewController!)
            
        } else if vc.isKindOfClass(UITabBarController.self) {
            
            let tabBarController = vc as! UITabBarController
            return UIWindow.getVisibleViewControllerFrom(tabBarController.selectedViewController!)
            
        } else {
            
            if let presentedViewController = vc.presentedViewController {
                
                return UIWindow.getVisibleViewControllerFrom(presentedViewController.presentedViewController!)
                
            } else {
                
                return vc;
            }
        }
    }
}