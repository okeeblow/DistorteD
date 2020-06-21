HYPE_THE_CORE = Gem::Specification::load(File.join(File.dirname(__FILE__), '..', 'DistorteD-Ruby', 'distorted.gemspec'))

Gem::Specification.new do |spec|
  spec.name          = 'distorted-jekyll'
  spec.version       = HYPE_THE_CORE.version
  spec.authors       = ['Allison Reid']
  spec.email         = ['root@cooltrainer.org']

  spec.summary       = 'Media transformation and embedding framework for Jekyll.'
  spec.description   = 'Jekyll::DistorteD is a Liquid tag for embedding media in a Jekyll site with automatic thumbnailing, cropping, and format conversion.'
  spec.homepage      = 'https://cooltrainer.org'
  spec.license       = 'AGPL-3.0'

  spec.files         = Dir['lib/**/*', 'LICENSE', 'README.md']
  spec.test_files    = Dir['spec/**/*']
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest', '~> 5.0'

  spec.add_dependency 'liquid', '~> 4.0'
  spec.add_dependency 'liquid-tag-parser', '~> 1.9'
  spec.add_dependency 'distorted', "~> #{HYPE_THE_CORE.version}"
  spec.add_dependency 'mime-types', '~> 3.0'
  spec.add_dependency 'kramdown', '~> 2.0'
end
