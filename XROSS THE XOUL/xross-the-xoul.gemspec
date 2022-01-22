require_relative('../i_was_the_one')


# Do the thing.
::Gem::Specification::new do |spec|
  # Shared default version/author/contact/minimum_ver/etc values.
  ::COOLTRAINER::DistorteD::I_WAS_THE_ONE.each_pair {
    spec.send(_1, _2)
  }

  spec.name          = 'xross-the-xoul'
  spec.summary       = 'DistorteD cross-platform t00lz.'
  spec.description   = 'Cross-CPU, cross-OS, cross-desktop, etc library for DistorteD.'

  spec.files         = ::Dir.glob('{bin,lib}/**/*').keep_if { |file| ::File.file?(file) } + %w(LICENSE README.md)
  spec.require_paths = ['lib']

  spec.add_development_dependency('test-unit', '~> 3.5')
end
