require_relative('i_was_the_one')


# Do the thing.
::Gem::Specification::new do |spec|
  # Shared default version/author/contact/minimum_ver/etc values.
  ::COOLTRAINER::DistorteD::I_WAS_THE_ONE.each_pair {
    spec.send(_1, _2)
  }

  spec.name          = 'distorted'
  spec.summary       = 'DistorteD operating environment.'
  spec.description   = 'Meta-Gem to install all available DistorteD Gems of the same version.'

  # We could leave this unset, but I'd rather avoid the "no files specified" warning.
  spec.files         = %w(LICENSE.md README.md)

  # Add a runtime dependency for every other gemspec in this repository regardless of nesting.
  ::Dir::glob("*/**/*.gemspec").map!(&::Gem::Specification::method(:load)).map!(&:name).each {
    spec.add_runtime_dependency(_1, "~> #{::COOLTRAINER::DistorteD::VERSION}")
  }
end
