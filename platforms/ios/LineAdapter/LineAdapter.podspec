Pod::Spec.new do |s|
  s.name         = "LineAdapter"
  s.version      = "3.2.1"

  s.license  = { :type => "Apache" }
  s.authors  = { "LINE" => "support@line.me" }
  s.homepage = "https://developers.line.me/"
  s.source   = { :git => "https://github.com/line/line-sdk-starter-ios.git", :tag => "master" }
  s.summary  = "LINE Login SDK"

  s.platform = :ios, "9.0"

  s.vendored_frameworks = "LineAdapter.framework"
  s.resource            = "LineAdapterUI.bundle"

  s.frameworks          = "Security", "CoreTelephony", "CoreGraphics", "CoreText"
  s.compiler_flags      = "-ObjC"
end
