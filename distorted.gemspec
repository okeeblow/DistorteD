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
    # Don't depend on mid-development components.
    # `::Gem::Specification#metadata` is supported since 2.0, but keys and values must be `::String`s.
    # We don't really care what the value is — if it's set at all then it's set.
    spec.add_runtime_dependency(_1, "~> #{::COOLTRAINER::DistorteD::VERSION}") unless spec.metadata.has_key?("experimental")
  }
end
