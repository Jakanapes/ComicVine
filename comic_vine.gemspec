# frozen_string_literal: true

require_relative "lib/comic_vine/version"

Gem::Specification.new do |gem|
  gem.name          = "comic_vine"
  gem.version       = ComicVine::VERSION
  gem.authors       = ["Patrick Sharp"]
  gem.email         = ["jakanapes@gmail.com"]
  gem.summary       = "Interface to the ComicVine API"
  gem.description   = "Simple API interface to Comic Vine. Allows for searches and returning specific information on resources."
  gem.homepage      = "https://github.com/Jakanapes/ComicVine"
  gem.license       = "MIT"
  gem.required_ruby_version = ">= 3.4"

  gem.metadata = {
    "homepage_uri" => gem.homepage,
    "source_code_uri" => gem.homepage,
    "changelog_uri" => "#{gem.homepage}/blob/master/CHANGELOG.md",
    "bug_tracker_uri" => "#{gem.homepage}/issues",
    "rubygems_mfa_required" => "true"
  }

  # No runtime dependencies — JSON parsing uses the stdlib.
  # Development dependencies live in the Gemfile.
  gem.files = Dir["lib/**/*.rb", "LICENSE", "README.md", "CHANGELOG.md"]
  gem.require_paths = ["lib"]
end
