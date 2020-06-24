Gem::Specification.new do |spec|
  spec.name          = 'distorted'
  spec.version       = '0.4.2'
  spec.authors       = ['Allison Reid']
  spec.email         = ['root@cooltrainer.org']

  spec.summary       = 'Media transformation framework core functionality.'
  spec.description   = 'Ruby implementation of core file-format operations used by DistorteD-Jekyll.'
  spec.homepage      = 'https://cooltrainer.org'
  spec.license       = 'AGPL-3.0'

  spec.files         = Dir['lib/**/*', 'LICENSE', 'README.md']
  spec.test_files    = Dir['test/**/*']
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest', '~> 5.0'

  spec.add_dependency 'gstreamer', '~> 3.4'
  spec.add_dependency 'mime-types', '~> 3.0'
  spec.add_dependency 'ruby-vips', '~> 2.0'
  spec.add_dependency 'svg_optimizer', '~> 0.2.5'
end
