require_relative('../i_was_the_one')

# Do the thing.
::Gem::Specification.new do |spec|
  # Shared default version/author/contact/minimum_ver/etc values.
  ::COOLTRAINER::DistorteD::I_WAS_THE_ONE.each_pair {
    spec.send(_1, _2)
  }

  spec.name          = 'distorted'
  spec.summary       = 'Multimedia toolkit core.'
  spec.description   = 'Ruby implementation of core file-format operations used by DistorteD-Jekyll.'

  spec.files         = ::Dir.glob('{bin,font,lib}/**/*').keep_if { |file| ::File.file?(file) } + %w(LICENSE README.md)
  spec.require_paths = ['lib']

  spec.executables = ['distorted']

  # Ours
  spec.add_runtime_dependency('checking-you-out', "~> #{COOLTRAINER::DistorteD::VERSION}")
  spec.add_runtime_dependency('xross-the-xoul', "~> #{COOLTRAINER::DistorteD::VERSION}")

  # Images
  spec.add_runtime_dependency('ruby-vips', '~> 2.0')  # https://github.com/libvips/ruby-vips
  spec.add_runtime_dependency('svg_optimizer', '~> 0.2.5')  # https://github.com/fnando/svg_optimizer

  # Video
  spec.add_runtime_dependency('gstreamer', '~> 3.4')  # https://ruby-gnome2.osdn.jp/ — https://github.com/ruby-gnome/ruby-gnome/tree/master/gstreamer/

  # Documents
  spec.add_runtime_dependency('hexapdf', '~> 0.13')  # https://github.com/gettalong/hexapdf — https://hexapdf.gettalong.org/
  spec.add_runtime_dependency('ffi-icu', '~> 0.3')  # https://github.com/erickguan/ffi-icu

  # Computer-y formats
  spec.add_runtime_dependency('ttfunk', '~> 1.6')  # https://github.com/prawnpdf/ttfunk — https://prawnpdf.org/
end
