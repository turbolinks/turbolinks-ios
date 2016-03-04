# Turbolinks for iOS

**Build high-fidelity hybrid apps with native navigation and a single shared web view.** Turbolinks for iOS provides the tooling to wrap your [Turbolinks 5](https://github.com/turbolinks/turbolinks)-enabled web app in a native iOS shell. It manages a single WKWebView instance across multiple view controllers, giving you native navigation UI with all the client-side performance benefits of Turbolinks.

## Features

- **Deliver fast, efficient HTML apps.** Avoid reloading JavaScript and CSS on every page. Save memory by reusing a single web view automatically.
- **Reuse mobile web views across platforms.** Create your views once, on the server. Deploy to iOS, [Android](https://github.com/turbolinks/turbolinks-android), and mobile browsers simultaneously.
- **Enhance web views with native UI.** Navigate your web views using native patterns. Easily augment web UI with native controls.
- **Produce large apps with small teams.** Achieve baseline HTML coverage for free. Upgrade to native views as needed.

## Requirements

Turbolinks for iOS is written in Swift 2.1 and requires iOS 9 or higher. Web views are backed by WKWebView for full-speed JavaScript performance.

## Installation

Install Turbolinks manually by building `Turbolinks.framework` and linking it to your project.

### Installing with Carthage

Add the following to your `Cartfile`:

    github "turbolinks/turbolinks-ios" "master"

Then run `carthage install`.

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

(high-level overview)

## Creating a Session

- Initialize a Turbolinks `Session` with a `WKWebViewConfiguration`
  - You can customize the configuration before passing it to the session
  - Changing the configuration after initializing the session has no effect on the web view.
- Set the session's delegate
  - The session's delegate should operate at a higher level than the session or visitable. This will typically be your AppDelegate or another top-level object (e.g., an ApplicationController).

## Implementing the Visitable Protocol

- Create a `UIViewController` that conforms to the `Visitable` protocol
- Your controller is responsible for performing the following actions as part of the `Visitable` protocol
  - Activating and deactivating the web view
  - Showing and hiding an activity indicator
  - Showing and hiding a screenshot
- Your controller should override `viewWillAppear` and `viewDidAppear` to notify its `visitableDelegate` when these events take place

## Responding to Visit Proposals

- When a visit is initiated from the web view, the session's `session(session: Session, didProposeVisitToURL URL: NSURL, withAction action: Action)` delegate method is called
- The delegate method is responsible for deciding how to handle the proposal, either by:
   - Creating a Visitable, presenting it, and performing a visit
   - Presenting a native view controller for the URL
   - Ignoring the proposal altogether

## Presenting Visitables

- Initialize a visitable and set its URL
- Present the visitable on the screen
- Call session.visit(visitable) to load its URL in the web view

# Building Your Turbolinks Application

## Starting and Stopping the Global Network Activity Indicator

## Responding to Non-Turbolinks Requests from the Web View

## Handling Failed Turbolinks Visits

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
