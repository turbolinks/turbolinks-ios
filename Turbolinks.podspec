Pod::Spec.new do |s|
  s.name         = "Turbolinks"
  s.version      = "0.0.1"
  s.summary      = "Turbolinks for iOS"
  s.homepage     = "http://github.com/basecamp/turbolinks-ios"
  s.license      = "MIT"
  s.authors      = { "Sam Stephenson" => "sam@basecamp.com", "Jeff Hardy" => "jeff@basecamp.com" }
  s.platform     = :ios, "9.0"
  s.source       = { :git => "git@github.com:basecamp/turbolinks-ios.git", :tag => "0.0.1" }
  s.source_files  = "Sources/*.swift"
  s.resources = "Sources/*.js"
  s.framework  = "WebKit"
  s.requires_arc = true
end
