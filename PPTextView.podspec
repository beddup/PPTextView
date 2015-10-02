#
#  Be sure to run `pod spec lint PPTextView.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#
Pod::Spec.new do |spec|
spec.name             = 'PPTextView'
spec.version          = '0.0.1'
spec.license          = { :type => 'MIT' }
spec.homepage         = 'https://github.com/beddup/PPTextView'
spec.authors          = { 'beddup' => 'beddup@163.com' }
spec.summary          = 'a custom UITextView.'
spec.source           = { :git => 'https://github.com/beddup/PPTextView.git', :tag => 'v0.0.1' }
spec.source_files     = 'PPTextView/*'
spec.framework        = 'SystemConfiguration'
spec.requires_arc     = true

end
