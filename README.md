# Turbolinks for iOS
Turbolinks for iOS is a Swift framework for iOS 9.0 and later that can be used to build hybrid apps that utilize [Turbolinks 5](https://github.com/turbolinks/turbolinks). This framework facilitates reusing a single `WKWebView` across different screens/view controllers to get the benefits of Turbolinks while allowing for native iOS integration and navigation.

View the demo app provided to see how to use it in practice (more documentation in the works).

## Installation

**Carthage**

```github "basecamp/turbolinks-ios" "master"```

**CocoaPods**

```
use_frameworks!
pod 'Turbolinks', :git => 'https://github.com/basecamp/turbolinks-ios.git'
```

You can also install it manually by building Turbolinks.framework and linking to your project

## Demo

There is a demo app and server in the repo. You can start the Sinatra demo server by running:

```
cd TurbolinksDemo/server
bundle
rackup
```

Open `turbolinks-ios.xcworkspace` and run the TurbolinksDemo target.