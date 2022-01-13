# Tie this Gem's version number directly to that of the core Gem
# since they share this repository.
require_relative '../DistorteD-Floor/lib/distorted/version'


# Do the thing.
Gem::Specification.new do |spec|
  spec.name          = 'distorted-booth'
  spec.version       = Cooltrainer::DistorteD::VERSION
  spec.authors       = ['okeeblow']
  spec.email         = ['root@cooltrainer.org']

  spec.summary       = 'DistorteD GUI.'
  spec.description   = 'Graphical interface for DistorteD multimedia toolkit.'
  spec.homepage      = 'https://cooltrainer.org'
  spec.license       = 'AGPL-3.0'

  spec.files         = Dir.glob('{bin,lib}/**/*').keep_if { |file| File.file?(file) } + %w(LICENSE README.md)
  spec.test_files    = Dir['test/**/*']
  spec.require_paths = ['lib']

  spec.executables   = ['distorted-booth']

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 10.0'

  spec.required_ruby_version = '>= 2.7.0'

  spec.add_dependency 'distorted', "~> #{Cooltrainer::DistorteD::VERSION}"
  spec.add_dependency 'tk', '~> 0.3.0'
end
