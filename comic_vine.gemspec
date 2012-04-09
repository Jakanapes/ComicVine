# -*- encoding: utf-8 -*-
require File.expand_path('../lib/comic_vine/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = "Patrick Sharp"
  gem.email         = "jakanapes@gmail.com"
  gem.description   = %q{Simple api interface to Comic Vine.  Allows for searches and returning specific information on resources.}
  gem.summary       = %q{Interface to ComicVine API}
  gem.homepage      = "https://github.com/Jakanapes/ComicVine"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "comic_vine"
  gem.require_paths = ["lib"]
  gem.version       = ComicVine::VERSION
  
  gem.add_dependency 'json'
end
