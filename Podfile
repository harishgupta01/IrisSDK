# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'IrisRtcSdk' do
# Uncomment the next line if you're using Swift or would like to use dynamic frameworks
use_frameworks!

# Pods for IrisRtcSdk

pod 'XMPPFramework', '~> 3.7.0'
pod 'libPhoneNumber-iOS', '~> 0.9'
end

post_install do |installer|
installer.pods_project.targets.each do |target|
target.build_configurations.each do |config|
config.build_settings['SWIFT_VERSION'] = '3.2'
end
end
end

target 'IrisRtcSdkTests' do
use_frameworks!
inherit! :search_paths
# Pods for testing
pod 'Unirest', '~> 1.1.4'
end


