
Pod::Spec.new do |s|
  s.name             = 'W3wSuggestionField'
  s.version          = '1.0.3'
  s.summary          = 'w3w-suggestion-objectivec allows you integrate w3w autosuggest  uitextfield component with storyboard'
  s.homepage         = 'https://github.com/what3words/w3w-autosuggest-textfield-objectivec.git'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.authors          = { "what3words" => "support@what3words.com" }
  s.source           = { :git => 'https://github.com/what3words/w3w-autosuggest-textfield-objectivec.git', :tag => s.version }
  s.ios.deployment_target = '10.0'
  s.requires_arc = true
  s.source_files = 'Sources/*.{h,m}'
  s.frameworks = 'UIKit'
  s.resource = 'Sources/images.xcassets'

end