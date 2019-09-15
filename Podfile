# Uncomment the next line to define a global platform for your project
 platform :ios, '11.0'

inhibit_all_warnings!

def import_pods
  pod 'RxCocoa'
  pod 'RxSwift'
  pod 'RealmSwift', '3.11.0'
  pod 'web3swift', :modular_headers => true
  pod 'Alamofire'
  pod 'ICONKit', :git => 'https://github.com/icon-project/iconkit', :branch => 'develop'
  pod 'PanModal'
  pod 'AcknowList'
end

inhibit_all_warnings!

target 'iconex_ios' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for iconex_ios
  import_pods
end

