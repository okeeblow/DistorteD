require_relative('../i_was_the_one')


# Do the thing.
::Gem::Specification.new do |spec|
  # Shared default version/author/contact/minimum_ver/etc values.
  ::COOLTRAINER::DistorteD::I_WAS_THE_ONE.each_pair {
    spec.send(_1, _2)
  }

  spec.name          = 'distorted-booth'
  spec.summary       = 'DistorteD GUI.'
  spec.description   = 'Graphical interface for DistorteD multimedia toolkit.'

  spec.files         = ::Dir.glob('{bin,lib}/**/*').keep_if { |file| ::File.file?(file) } + %w(LICENSE README.md)
  spec.require_paths = ['lib']

  spec.executables   = ['distorted-booth']

  spec.add_development_dependency('bundler', '~> 2.0')
  spec.add_development_dependency('rake', '~> 10.0')

  spec.add_runtime_dependency('distorted', "~> #{COOLTRAINER::DistorteD::VERSION}")
  spec.add_runtime_dependency('tk', '~> 0.3.0')
end
