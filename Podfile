# Uncomment the next line to define a global platform for your project
platform :osx, '10.12'

def shared_pods
	pod 'Alamofire', '~> 4.8'
	pod 'PromiseKit/Alamofire', '~> 6.0'
	pod 'KeychainAccess', '~> 3.2'
#	pod 'SwiftLint'
	pod 'Fabric'
	pod 'Crashlytics'
	pod 'Sparkle', '~> 1.21'
	pod 'LetsMove', '~> 1.24'
end

target 'MoJob' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for MoJob
	shared_pods

  target 'MoJobTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'MoJobUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end

target 'MoJob Dev' do
	use_frameworks!

	shared_pods
end
