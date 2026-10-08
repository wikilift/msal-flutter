Pod::Spec.new do |s|
  s.name = 'flutter_msal_plus'
  s.version = '1.0.0'
  s.summary = 'Native Microsoft Authentication Library integration for Flutter.'
  s.description = 'Interactive and silent authentication, account management, and native MSAL cache integration.'
  s.homepage = 'https://github.com/wikilift/msal-flutter'
  s.license = { :type => 'BSD-3-Clause', :file => '../LICENSE' }
  s.author = 'WikiLift'
  s.source = { :git => 'https://github.com/wikilift/msal-flutter.git', :tag => s.version.to_s }
  s.source_files = 'flutter_msal_plus/Sources/flutter_msal_plus/**/*.swift'
  s.dependency 'Flutter'
  s.dependency 'MSAL', '2.0.0'
  s.swift_version = '5.0'
  s.platform = :ios, '15.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
