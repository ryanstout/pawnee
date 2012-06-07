# -*- encoding: utf-8 -*-
require File.expand_path('../lib/pawnee/pawnee/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Ryan Stout"]
  gem.email         = ["ryanstout@gmail.com"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "pawnee"
  gem.require_paths = ["lib/pawnee"]
  gem.add_runtime_dependency 'bundler'
  gem.add_runtime_dependency 'thor', '>= 0.14.6'
  gem.add_runtime_dependency 'net-ssh', '= 2.2.2'
  gem.add_runtime_dependency 'net-sftp', '= 2.0.5'
  gem.add_runtime_dependency 'thor-ssh'
  gem.add_runtime_dependency 'activemodel', "~> 3.2.3"
  gem.add_runtime_dependency 'activesupport', "~> 3.2.3"
  gem.add_development_dependency "turn"
  gem.add_development_dependency 'rspec', '~> 2.10'
  gem.add_development_dependency 'vagrant', '= 1.0.3'
  gem.add_development_dependency 'sahara', '>= 0.0.11'
  gem.add_development_dependency 'rake', '~> 0.9'
  gem.add_development_dependency 'rdoc', '~> 3.9'
  gem.version       = Pawnee::VERSION
end
