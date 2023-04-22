require_relative('../i_was_the_one')


# Do the thing.
::Gem::Specification::new do |spec|
  # Shared default version/author/contact/minimum_ver/etc values.
  ::COOLTRAINER::DistorteD::I_WAS_THE_ONE.each_pair {
    spec.send(_1, _2)
  }

  spec.name          = 'globeglitter'
  spec.summary       = 'Surrogate keys'
  spec.description   = 'DistorteD UUID/GUID library'

  spec.files         = ::Dir.glob('{bin,lib}/**/*').keep_if { |file| ::File.file?(file) } + %w(LICENSE README.md)
  spec.require_paths = ['lib']

  spec.add_runtime_dependency('xross-the-xoul', "~> #{COOLTRAINER::DistorteD::VERSION}")

  spec.add_development_dependency('test-unit', '~> 3.5')
  spec.add_development_dependency('ruby-prof', '~> 1.4')
  spec.add_development_dependency('memory_profiler', '~> 1.0')  # https://github.com/SamSaffron/memory_profiler
  spec.add_development_dependency('benchmark-ips', '~> 2.0')  # https://github.com/evanphx/benchmark-ips
end
