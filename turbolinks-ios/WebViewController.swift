import UIKit
import WebKit

class WebViewController: UIViewController {
    @IBOutlet var mainView : UIView?

    let URL = NSURL(string: "http://turbolinks.dev/")
    var webView: WKWebView?

    override func loadView() {
        super.loadView()
        self.webView = WKWebView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.webView!.loadRequest(NSURLRequest(URL: URL!))
        self.view = webView
    }
}
