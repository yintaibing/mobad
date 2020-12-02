#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint bloom_ad.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'mobad'
  s.version          = '2.1.0'
  s.summary          = 'Flutter plugin for grow higher ad revenue.'
  s.description      = <<-DESC
Flutter plugin for grow higher ad revenue.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'MobAD' => 'ad@ad.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'Aspects'
  s.dependency 'AFNetworking'
  s.dependency 'MJExtension'
  s.dependency 'ReactiveObjC'
  s.dependency 'Bytedance-UnionAD-Dynamic', '3.3.0.5'
  s.dependency 'GDTMobSDK-Dynamic', '4.11.12'
  s.dependency 'KSAdSDKFull', '3.3.7'
  s.dependency 'MobADSDK', '~> 2.2.0'
  s.platform = :ios, '9.0'

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
end
