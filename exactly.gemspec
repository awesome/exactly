# -*- encoding: utf-8 -*-
require File.expand_path('../lib/exactly/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Jacob Atzen"]
  gem.email         = ["jacob@incremental.dk"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "exactly"
  gem.require_paths = ["lib"]
  gem.version       = Exactly::VERSION
  gem.add_dependency "savon",  ">= 0.9.5"
end
