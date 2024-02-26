#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint simple_secure_storage.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'simple_secure_storage'
  s.version          = '0.0.1'
  s.summary          = 'Simple and secure storage for Flutter.'
  s.description      = <<-DESC
Simple secure storage for Flutter.
                       DESC
  s.homepage         = 'https://github.com/Skyost/SimpleSecureStorage'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Skyost' => 'me@skyost.eu' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.ios.dependency 'Flutter'
  s.osx.dependency 'FlutterMacOS'
  s.ios.deployment_target = '11.0'
  s.osx.deployment_target = '10.11'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
