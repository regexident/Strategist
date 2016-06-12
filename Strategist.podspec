Pod::Spec.new do |s|

  s.name         = "Strategist"
  s.version      = "0.1.0"
  s.summary      = "Algorithms for building strong immutable AIs for round-based games."

  s.description  = <<-DESC
                   Strategist provides algorithms for building strong immutable AIs for round-based games.
                   DESC

  s.homepage     = "https://github.com/regexident/Strategist"
  s.license      = { :type => 'MPL-2', :file => 'LICENSE' }
  s.author       = { "Vincent Esche" => "regexident@gmail.com" }
  s.source       = { :git => "https://github.com/regexident/Strategist.git", :tag => '0.1.0' }
  s.source_files  = "Sources/*.{swift,h,m}"
  s.requires_arc = true
  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.9"
  
end