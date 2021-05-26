# Tie this Gem's version number directly to that of the core Gem
# since they share this repository.
require_relative '../DistorteD-Floor/lib/distorted/version'


# Do the thing.
Gem::Specification.new do |spec|
  spec.name          = 'checking-you-out'
  spec.version       = Cooltrainer::DistorteD::VERSION
  spec.authors       = ['okeeblow']
  spec.email         = ['root@cooltrainer.org']

  spec.summary       = 'DistorteD file/stream/media identification toolz.'
  spec.description   = 'File type identification library.'
  spec.homepage      = 'https://cooltrainer.org'
  spec.license       = 'AGPL-3.0'

  spec.files         = Dir.glob('{bin,lib,mime,third-party}/**/*').keep_if { |file| File.file?(file) } + %w(LICENSE README.md)
  spec.test_files    = Dir['test/**/*']
  spec.require_paths = ['lib']

  spec.executables   = ['checking-you-out']

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest', '~> 5.0'

  spec.add_development_dependency 'mime-types', '~> 3.3'  # https://github.com/mime-types/ruby-mime-types
  spec.add_development_dependency 'mini_mime', '~> 1.1'  # https://github.com/discourse/mini_mime

  spec.add_development_dependency 'fasterer', '~> 0.9'  # https://github.com/DamirSvrtan/fasterer
  spec.add_development_dependency 'profile', '~> 0.4'  # https://github.com/ruby/profile

  spec.required_ruby_version = '>= 2.7.0'

end
