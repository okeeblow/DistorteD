require_relative('../i_was_the_one')


# Do the thing.
::Gem::Specification.new do |spec|
  # Shared default version/author/contact/minimum_ver/etc values.
  ::COOLTRAINER::DistorteD::I_WAS_THE_ONE.each_pair {
    spec.send(_1, _2)
  }

  spec.name          = 'distorted-jekyll'
  spec.summary       = 'Multimedia toolkit for Jekyll websites.'
  spec.description   = 'Jekyll::DistorteD is a Liquid tag for embedding media in a Jekyll site with automatic thumbnailing, cropping, and format conversion.'

  spec.files         = ::Dir.glob('lib/**/*').keep_if { |file| ::File.file?(file) } + %w(LICENSE README.md)
  spec.require_paths = ['lib']

  spec.add_runtime_dependency('liquid', '~> 4.0')
  spec.add_runtime_dependency('liquid-tag-parser', '~> 2.0')
  spec.add_runtime_dependency('distorted', "~> #{::COOLTRAINER::DistorteD::VERSION}")
  spec.add_runtime_dependency('kramdown', '~> 2.0')
end
