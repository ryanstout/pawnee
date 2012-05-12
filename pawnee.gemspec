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
  gem.add_runtime_dependency 'thor'
  gem.add_runtime_dependency 'net-ssh'
  gem.add_runtime_dependency 'net-sftp'
  gem.add_development_dependency "minitest"
  gem.add_development_dependency "turn"
  gem.version       = Pawnee::VERSION
end
