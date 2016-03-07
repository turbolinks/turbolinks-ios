# Turbolinks for iOS

**Build high-fidelity hybrid apps with native navigation and a single shared web view.** Turbolinks for iOS provides the tooling to wrap your [Turbolinks 5](https://github.com/turbolinks/turbolinks)-enabled web app in a native iOS shell. It manages a single WKWebView instance across multiple view controllers, giving you native navigation UI with all the client-side performance benefits of Turbolinks.

## Features

- **Deliver fast, efficient hybrid apps.** Avoid reloading JavaScript and CSS. Save memory by sharing one WKWebView.
- **Reuse mobile web views across platforms.** Create your views once, on the server, in HTML. Deploy them to iOS, [Android](https://github.com/turbolinks/turbolinks-android), and mobile browsers simultaneously. Ship new features without waiting on App Store approval.
- **Enhance web views with native UI.** Navigate web views using native patterns. Augment web UI with native controls.
- **Produce large apps with small teams.** Achieve baseline HTML coverage for free. Upgrade to native views as needed.

## Requirements

Turbolinks for iOS is written in Swift 2.1 and requires iOS 9 or higher. Web views are backed by [WKWebView](https://developer.apple.com/library/ios/documentation/WebKit/Reference/WKWebView_Ref/) for full-speed JavaScript performance.

**Note:** You should understand how Turbolinks works with web applications in the browser before attempting to use Turbolinks for iOS. See the [Turbolinks 5 documentation](https://github.com/turbolinks/turbolinks) for details.

## Installation

Install Turbolinks manually by building `Turbolinks.framework` and linking it to your project.

### Installing with Carthage

Add the following to your `Cartfile`:

```
github "turbolinks/turbolinks-ios" "master"
```

Then run `carthage update`.

### Installing with CocoaPods

Add the following to your `Podfile`:

```ruby
use_frameworks!
pod 'Turbolinks', :git => 'https://github.com/turbolinks/turbolinks-ios.git'
```

Then run `pod install`.

## Running the Demo

Turbolinks for iOS includes a demo application to show off features of the framework.

The demo includes a simple HTTP server that serves a Turbolinks 5 web app on `localhost` at port 9292. To start the server, run `TurbolinksDemo/demo-server` from the command line.

To start the demo application in the Simulator, open `turbolinks-ios.xcworkspace` and run the TurbolinksDemo target.


# Understanding Turbolinks Concepts

The Session class is the central coordinator in a Turbolinks for iOS application. It creates and manages a single WKWebView instance, and lets its delegate—your application—choose how to handle link taps, present view controllers, and deal with network errors.

A Visitable is a UIViewController that can be visited by the Session. Each Visitable view controller provides a VisitableView instance, which acts as a container for the Session’s shared WKWebView. The VisitableView has a pull-to-refresh control and an activity indicator. It also displays a screenshot of its contents when the web view moves to another VisitableView.

When you tap a Turbolinks-enabled link in the web view, the Session asks your application how to handle the link’s URL. Most of the time, your application will visit the URL by creating and presenting a Visitable. But it might also choose to present a native view controller for the URL, or to ignore the URL entirely.

## Creating a Session

To create a Session, first create a [WKWebViewConfiguration](https://developer.apple.com/library/ios/documentation/WebKit/Reference/WKWebViewConfiguration_Ref/index.html) and configure it as needed (see [Customizing the Web View Configuration](#customizing-the-web-view-configuration) for details). Then pass this configuration to the Session initializer and set the `delegate` property on the returned instance.

```swift
import Turbolinks

class ...: ..., SessionDelegate {
    lazy var session: Session = {
        let configuration = WKWebViewConfiguration()
        let session = Session(webViewConfiguration: configuration)
        session.delegate = self
        return session
    }()
}
```

The Session’s delegate should act as a top-level coordinator in your application, and must implement the following methods.

```swift
func session(session: Session, didProposeVisitToURL URL: NSURL, withAction action: Action)
```

Turbolinks for iOS calls the `session:didProposeVisitToURL:withAction:` method before every visit, such as when you tap a Turbolinks-enabled link or call `Turbolinks.visit(...)` in your web application. Implement this method to choose how to handle the specified URL and action.

See [Responding to Visit Proposals](#responding-to-visit-proposals) for more details.

```swift
func session(session: Session, didFailRequestForVisitable visitable: Visitable, withError error: NSError)
```

Turbolinks calls `session:didFailRequestForVisitable:withError:` when a visit’s network request fails. Use this method to respond to the error by displaying an appropriate message, or by requesting authentication credentials in the case of an authorization failure.

See [Handling Failed Turbolinks Visits](#handling-failed-turbolinks-visits) for more details.

## Working with Visitables

Visitable view controllers must conform to the Visitable protocol by implementing the following three properties:

```swift
protocol Visitable {
    weak var visitableDelegate: VisitableDelegate? { get set }
    var visitableView: VisitableView! { get }
    var visitableURL: NSURL! { get }
}
```

Turbolinks for iOS provides a VisitableViewController class that implements the Visitable protocol for you. This view controller displays the VisitableView as its single subview.

Most applications will want to subclass VisitableViewController to customize its layout or add additional views. For example, the bundled demo application has a [DemoViewController subclass](TurbolinksDemo/DemoViewController.swift) that can display a custom error view in place of the VisitableView.

If your application’s design prevents you from subclassing VisitableViewController, you can implement the Visitable protocol yourself. See the [VisitableViewController implementation](Turbolinks/VisitableViewController.swift) for details.

Note that custom Visitable view controllers must forward their `viewWillAppear` and `viewDidAppear` methods to the Visitable delegate’s `visitableViewWillAppear` and `visitableViewDidAppear` methods. The Session uses these hooks to know when it should move the WKWebView from one VisitableView to another.


# Building Your Turbolinks Application

## Initiating a Visit

To visit a URL with Turbolinks, first instantiate a Visitable view controller. Then present the view controller and pass it to the Session’s `visit` method.

The framework provides a default Visitable implementation called VisitableViewController which you can subclass or use directly. For example, to create, display, and visit a VisitableViewController in a UINavigationController-based application, you might write:

```swift
let visitable = VisitableViewController()
visitable.URL = NSURL(string: "http://localhost:9292/")!

navigationController.pushViewController(visitable, animated: true)
session.visit(visitable)
```

## Responding to Visit Proposals

When you tap a Turbolinks-enabled link, the tap makes its way from the web view to the Session as a proposed visit. Your Session’s delegate must implement the `session:didProposeVisitToURL:withAction:` method to choose how to act on each proposal.

Normally you’ll respond to a visit proposal by simply initiating a visit and loading the URL with Turbolinks. See [Initiating a Visit](#initiating-a-visit) for more details.

### Handling Visit Actions

Each proposed visit has an Action, which tells you how you should present the Visitable.

The default Action is `.Advance`. In most cases you’ll respond to an advance visit by pushing a Visitable view controller for the URL onto the navigation stack.

When you follow a link annotated with `data-turbolinks-action="replace"`, the proposed Action will be `.Replace`. Usually you’ll want to handle a replace visit by popping the topmost view controller in the navigation stack and pushing a new Visitable view controller for the proposed URL without animation.


## Handling Failed Turbolinks Visits

## Setting Visitable Titles

By default, Turbolinks for iOS sets your Visitable view controller’s `title` property to the page’s `<title>`.

If you want to customize the title or pull it from another element on the page, you can implement the `visitableDidRender` method on your Visitable:

```swift
func visitableDidRender() {
    title = formatTitle(visitableView.webView?.title)
}

func formatTitle(title: String) -> String {
    // ...
}
```

## Starting and Stopping the Global Network Activity Indicator

Implement the optional `sessionDidStartRequest:` and `sessionDidFinishRequest:` methods in your application’s Session delegate to show the global network activity indicator in the status bar while Turbolinks issues network requests.

```swift
func sessionDidStartRequest(session: Session) {
    UIApplication.sharedApplication().networkActivityIndicatorVisible = true
}

func sessionDidFinishRequest(session: Session) {
    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
}
```

Note that the network activity indicator is a shared resource, so your application will need to perform its own reference counting if other background operations update the indicator state.

## Changing How Turbolinks Opens External Links

By default, Turbolinks for iOS opens external links in Safari. You can change this behavior by becoming the WKWebView’s `navigationDelegate` and implementing the [`webView:decidePolicyForNavigationAction:decisionHandler:`](https://developer.apple.com/library/ios/documentation/WebKit/Reference/WKNavigationDelegate_Ref/#//apple_ref/occ/intfm/WKNavigationDelegate/webView:decidePolicyForNavigationAction:decisionHandler:) method yourself.

To assign the web view’s `navigationDelegate` property, implement the Session delegate’s optional `sessionDidLoadWebView:` method. Turbolinks calls this method after every “cold boot,” such as on the initial page load and after pulling to refresh the page.

```swift
func sessionDidLoadWebView(session: Session) {
    session.webView.navigationDelegate = self
}

func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> ()) {
    decisionHandler(WKNavigationActionPolicy.Cancel)
    // ...
}
```

Note that your application _must_ call the navigation delegate’s `decisionHandler` with `WKNavigationActionPolicy.Cancel` to prevent external URLs from loading in the Turbolinks-managed web view.

## Customizing the Web View Configuration

### Setting a Custom User-Agent

### Sharing a Process Pool with Other Web Views

### Injecting Custom JavaScript Into the Web View


# Contributing to Turbolinks

Turbolinks for iOS is open-source software, freely distributable under the terms of an [MIT-style license](LICENSE). The [source code is hosted on GitHub](https://github.com/turbolinks/turbolinks-ios).
Development is sponsored by [Basecamp](https://basecamp.com/).

We welcome contributions in the form of bug reports, pull requests, or thoughtful discussions in the [GitHub issue tracker](https://github.com/turbolinks/turbolinks-ios/issues).

Please note that this project is released with a [Contributor Code of Conduct](CONDUCT.md). By participating in this project you agree to abide by its terms.

---

© 2016 Basecamp, LLC
