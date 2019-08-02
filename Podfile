# Uncomment the next line to define a global platform for your project
platform :osx, '10.12'

def shared_pods
	pod 'Alamofire', '~> 4.8'
	pod 'PromiseKit/Alamofire', '~> 6.0'
	pod 'KeychainAccess', '~> 3.1'
	pod 'SwiftLint'
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
