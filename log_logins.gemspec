require File.expand_path('../lib/log_logins/version', __FILE__)

Gem::Specification.new do |s|
  s.name          = "log_logins"
  s.description   = %q{A Rails library for logging login attempts and blocking as appropriate.}
  s.summary       = s.description
  s.homepage      = "https://github.com/adamcooke/log_logins"
  s.licenses      = ['MIT']
  s.version       = LogLogins::VERSION
  s.files         = Dir.glob("{lib,db}/**/*")
  s.require_paths = ["lib"]
  s.authors       = ["Adam Cooke"]
  s.email         = ["me@adamcooke.io"]
  s.cert_chain    = ['certs/adamcooke.pem']
  s.signing_key   = File.expand_path("~/.ssh/gem-private_key.pem") if $0 =~ /gem\z/
  s.add_dependency 'activerecord'
end
