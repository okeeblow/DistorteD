# Load version string from a shared constant in a subdir of this Gem root.
# Only chdir for the Gem build after we've imported the version constant,
# or `require_relative` will try to double up the root directory:
# 'Invalid gemspec in [DistorteD-Ruby/distorted.gemspec]: cannot load such file
#  -- /home/okeeblow/Works/DistorteD/DistorteD-Ruby/DistorteD-Ruby/lib/distorted/version'
require_relative 'lib/distorted/version'

# Do the thing.
Gem::Specification.new do |spec|
  spec.name          = 'distorted'
  spec.version       = Cooltrainer::DistorteD::VERSION
  spec.authors       = ['okeeblow']
  spec.email         = ['root@cooltrainer.org']

  spec.summary       = 'Multimedia toolkit core.'
  spec.description   = 'Ruby implementation of core file-format operations used by DistorteD-Jekyll.'
  spec.homepage      = 'https://cooltrainer.org'
  spec.license       = 'AGPL-3.0'

  # "The optional base keyword argument specifies the base directory for interpreting relative pathnames instead of the current working directory. As the results are not prefixed with the base directory name in this case, you will need to prepend the base directory name if you want real paths."
  spec.files         = Dir.glob('{font,lib}/**/*').keep_if { |file| File.file?(file) } + %w(LICENSE README.md)
  spec.test_files    = Dir['test/**/*']
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.7.0'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest', '~> 5.0'

  spec.add_dependency 'gstreamer', '~> 3.4'
  spec.add_dependency 'mime-types', '~> 3.0'
  spec.add_dependency 'ruby-filemagic', '~> 0.7'
  spec.add_dependency 'ruby-vips', '~> 2.0'
  spec.add_dependency 'svg_optimizer', '~> 0.2.5'
  spec.add_dependency 'hexapdf', '~> 0.11.9'
  spec.add_dependency 'ttfunk', '~> 1.6'
  spec.add_dependency 'charlock_holmes', '~> 0.7'
end
