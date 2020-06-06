
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "distorted-jekyll/version"

Gem::Specification.new do |spec|
  spec.name          = "distorted-jekyll"
  spec.version       = Jekyll::DistorteD::VERSION
  spec.authors       = ["Allison Reid"]
  spec.email         = ["root@cooltrainer.org"]

  spec.summary       = "Media thumbnailing, embedding, and linking framework for Jekyll."
  spec.description   = "Jekyll::DistorteD is a Liquid tag for embedding media in my Jekyll blog with automatic thumbnailing."
  spec.homepage      = "https://cooltrainer.org"
  spec.license       = "AGPL-3.0"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"

  spec.add_dependency "liquid", "~> 4.0"
  spec.add_dependency "liquid-tag-parser", "~> 1.9"
  spec.add_dependency "distorted", "~> 0.3"
  spec.add_dependency "mime-types", "~> 3.0"
  spec.add_dependency "kramdown", "~> 2.0"
end
