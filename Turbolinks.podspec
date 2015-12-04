Pod::Spec.new do |s|
  s.name         = "Turbolinks"
  s.version      = "0.0.1"
  s.summary      = "Turbolinks for iOS"
  s.homepage     = "http://github.com/basecamp/turbolinks-ios"
  s.license      = "MIT"
  s.authors      = { "Sam Stephenson" => "sam@basecamp.com", "Jeff Hardy" => "jeff@basecamp.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "git@github.com:basecamp/turbolinks-ios.git", :tag => "0.0.1" }
  s.source_files  = "Turbolinks/*.swift"
  s.resources = "Turbolinks/*.js"
  s.framework  = "WebKit"
  s.requires_arc = true
end
