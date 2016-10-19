#
#  Be sure to run `pod spec lint PopupViewController.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  s.name         = "ABModel"
  s.version      = "0.1.1"
  s.summary      = "simple class to parse REST response"
  s.description  = <<-DESC
  multiple micro lib to bootstrap ios apps"
                   DESC
  s.homepage     = "https://github.com/AlexandreBarbier/ABModel"

  s.license      = "MIT"
  s.author             = { "Alexandre Barbier" => "alexandr.barbier@gmail.com" }
  s.social_media_url   = "http://twitter.com/abarbier_"

  s.platform     = :ios, "8.0"

  s.source       = { :git => "https://github.com/AlexandreBarbier/ABModel.git", :tag => "#{s.version}" }
  s.source_files  = "ABModel/*.swift"

end
