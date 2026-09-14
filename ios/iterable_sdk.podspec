#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint iterable_sdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'iterable_sdk'
  s.version          = '0.1.0'
  s.summary          = 'Flutter plugin wrapping the Iterable iOS SDK.'
  s.description      = <<-DESC
Flutter plugin wrapping Iterable's native Android and iOS SDKs (identity,
events, commerce, push, in-app, embedded messages, and JWT auth).
                       DESC
  s.homepage         = 'https://github.com/beyondmenu/flutter_iterable'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'BeyondMenu' => 'mobile@beyondmenu.com' }
  s.source           = { :path => '.' }
  s.source_files = 'iterable_sdk/Sources/iterable_sdk/**/*'
  s.dependency 'Flutter'
  s.dependency 'Iterable-iOS-SDK', '~> 6.7.5'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'iterable_sdk_privacy' => ['iterable_sdk/Sources/iterable_sdk/PrivacyInfo.xcprivacy']}
end
