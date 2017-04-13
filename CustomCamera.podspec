Pod::Spec.new do |s|

# 1
s.platform = :ios
s.ios.deployment_target = '8.0'
s.name = "CustomCamera"
s.summary = "CustomCamera has instagram like custom camera and library to get images/videos and edit images"
s.requires_arc = true

# 2
s.version = "0.3.1"

# 3
s.license = { :type => "MIT", :file => "LICENSE" }

# 4 - Replace with your name and e-mail address
s.author = { "[Damandeep Kaur]" => "[daman.bisoncode@gmail.com]" }

# 5 - Replace this URL with your own Github page's URL (from the address bar)
s.homepage = "https://github.com/Daman1208/CustomCamera"

# 6 - Replace this URL with your own Git URL from "Quick Setup"
s.source = { :git => "https://github.com/Daman1208/CustomCamera.git", :tag => "#{s.version}"}

# 7
s.framework = "UIKit"
s.framework = "Foundation"
s.framework = "Photos"
s.framework = "CoreLocation"
s.framework = "AssetsLibrary"
s.dependency 'SDWebImage'
s.dependency 'SCRecorder'

# 8
s.source_files = "CustomCamera/**/*.{h,m}"

# 9
s.resources = "CustomCamera/**/*.{png,jpeg,jpg,storyboard,xib,strings,bundle}"


end
