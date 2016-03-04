# Turbolinks for iOS

**Build high-fidelity hybrid apps with native navigation and a single shared web view.**

- wraps a Turbolinks 5 web app to avoid reloading on every page
- shares a single web view across multiple view controllers for performance and memory benefits
- gives you baseline coverage with web views, and allows you to easily upgrade to native views as necessary


- swift 2
- ios 9
- wkwebview

## Installation

You can also install Turbolinks manually by building `Turbolinks.framework` and linking it to your project.

### Installing with Carthage

```github "turbolinks/turbolinks-ios" "master"```

### Installing with CocoaPods

```
use_frameworks!
pod 'Turbolinks', :git => 'https://github.com/turbolinks/turbolinks-ios.git'
```

## Running the Demo

`TurbolinksDemo/demo-server`

Open `turbolinks-ios.xcworkspace` and run the TurbolinksDemo target.

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
