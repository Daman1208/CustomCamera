Pod::Spec.new do |s|

# 1
s.platform = :ios
s.ios.deployment_target = '8.0'
s.name = "CustomCamera"
s.summary = "CustomCamera has instagram like custom camera and library to get images/videos and edit images"
s.requires_arc = true

# 2
s.version = "0.3.0"

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
s.resources = "CustomCamera/**/*.{png,jpeg,jpg,storyboard,xib,strings}"

s.header_mappings_dir = "CLImageEditor"
s.default_subspec = "Core"

s.subspec 'Core' do |core|
core.source_files  = 'CLImageEditor/*.{h,m,mm}', 'CLImageEditor/**/*.{h,m,mm}'
core.public_header_files = 'CLImageEditor/*.h'
core.resources = "CLImageEditor/*.bundle"
end

s.subspec 'Dev' do |dev|
dev.dependency 'CLImageEditor/Core'
dev.source_files        = 'CLImageEditor/*/*.h', 'CLImageEditor/ImageTools/ToolSettings/*.h', 'CLImageEditor/ImageTools/CLFilterTool/CLFilterBase.h', 'CLImageEditor/ImageTools/CLEffectTool/CLEffectBase.h'
dev.public_header_files = 'CLImageEditor/*/*.h', 'CLImageEditor/ImageTools/ToolSettings/*.h', 'CLImageEditor/ImageTools/CLFilterTool/CLFilterBase.h', 'CLImageEditor/ImageTools/CLEffectTool/CLEffectBase.h'
end

s.subspec 'AllTools' do |all|
all.dependency 'CLImageEditor/Core'
all.dependency 'CLImageEditor/StickerTool'
all.dependency 'CLImageEditor/EmoticonTool'
all.dependency 'CLImageEditor/ResizeTool'
all.dependency 'CLImageEditor/TextTool'
all.dependency 'CLImageEditor/SplashTool'
end

s.subspec 'StickerTool' do |sub|
sub.dependency 'CLImageEditor/Core'
sub.source_files  = 'OptionalImageTools/CLStickerTool/*.{h,m,mm}'
sub.private_header_files = 'OptionalImageTools/CLStickerTool/**.h'
sub.header_mappings_dir = 'OptionalImageTools/CLStickerTool/'
end

s.subspec 'EmoticonTool' do |sub|
sub.dependency 'CLImageEditor/Core'
sub.source_files  = 'OptionalImageTools/CLEmoticonTool/*.{h,m,mm}'
sub.private_header_files = 'OptionalImageTools/CLEmoticonTool/**.h'
sub.header_mappings_dir = 'OptionalImageTools/CLEmoticonTool/'
end

s.subspec 'ResizeTool' do |sub|
sub.dependency 'CLImageEditor/Core'
sub.source_files  = 'OptionalImageTools/CLResizeTool/*.{h,m,mm}'
sub.private_header_files = 'OptionalImageTools/CLResizeTool/**.h'
sub.header_mappings_dir = 'OptionalImageTools/CLResizeTool/'
end

s.subspec 'TextTool' do |sub|
sub.dependency 'CLImageEditor/Core'
sub.source_files  = 'OptionalImageTools/CLTextTool/*.{h,m,mm}'
sub.private_header_files = 'OptionalImageTools/CLTextTool/**.h'
sub.header_mappings_dir = 'OptionalImageTools/CLTextTool/'
end

s.subspec 'SplashTool' do |sub|
sub.dependency 'CLImageEditor/Core'
sub.source_files  = 'OptionalImageTools/CLSplashTool/*.{h,m,mm}'
sub.private_header_files = 'OptionalImageTools/CLSplashTool/**.h'
sub.header_mappings_dir = 'OptionalImageTools/CLSplashTool/'
end

end
