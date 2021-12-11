# Tie this Gem's version number directly to that of the core Gem
# since they share this repository.
require_relative('../DistorteD-Floor/lib/distorted/version')


# Do the thing.
::Gem::Specification::new do |spec|
  spec.name          = 'xross-the-xoul'
  spec.version       = ::Cooltrainer::DistorteD::VERSION
  spec.authors       = ['okeeblow']
  spec.email         = ['root@cooltrainer.org']

  spec.summary       = 'DistorteD cross-platform t00lz.'
  spec.description   = 'Cross-CPU, cross-OS, cross-desktop, etc library for DistorteD.'
  spec.homepage      = 'https://cooltrainer.org'
  spec.license       = 'AGPL-3.0'

  spec.files         = ::Dir.glob('{bin,lib}/**/*').keep_if { |file| File.file?(file) } + %w(LICENSE README.md)
  spec.test_files    = ::Dir['TEST MY BEST/**/*']
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 3.0.0'

  spec.add_development_dependency 'test-unit'
end
