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
  spec.files         = Dir.glob('{bin,font,lib}/**/*').keep_if { |file| File.file?(file) } + %w(LICENSE README.md)
  spec.test_files    = Dir['test/**/*']
  spec.require_paths = ['lib']

  spec.executables = ['distorted']

  spec.required_ruby_version = '>= 2.7.0'

  spec.add_development_dependency 'bundler', '~> 2.2'  # https://bundler.io/ — https://github.com/rubygems/rubygems/tree/master/bundler
  spec.add_development_dependency 'rake', '~> 13.0'  # https://ruby.github.io/rake/ — https://github.com/ruby/rake
  spec.add_development_dependency 'minitest', '~> 5.14'  # http://docs.seattlerb.org/minitest/ — https://github.com/seattlerb/minitest

  # Kaital Struct seems like it might be a good fit for DistorteD,
  # but it's read-only in 1.x and I think it's generally kinda awkward
  # idk the all-YAML separate-compiler thing is a huge turnoff for me
  # https://doc.kaitai.io/
  # https://doc.kaitai.io/faq.html#writing
  # https://github.com/kaitai-io/kaitai_struct_ruby_runtime

  # https://github.com/dmendel/bindata will probably be useful.

  # Ours
  spec.add_dependency 'checking-you-out', "~> #{Cooltrainer::DistorteD::VERSION}"

  # Common
  spec.add_dependency 'mime-types', '~> 3.3'  # https://github.com/mime-types/ruby-mime-types
  spec.add_dependency 'ruby-filemagic', '~> 0.7'  # http://blackwinter.github.io/ruby-filemagic/ https://github.com/blackwinter/ruby-filemagic
  # FYI: Unmaintained!! https://github.com/blackwinter/ruby-filemagic/commit/e1f2efd07da4130484f06f58fed016d9eddb4818

  # Images
  spec.add_dependency 'ruby-vips', '~> 2.0'  # https://github.com/libvips/ruby-vips
  spec.add_dependency 'svg_optimizer', '~> 0.2.5'  # https://github.com/fnando/svg_optimizer

  # Video
  spec.add_dependency 'gstreamer', '~> 3.4'  # https://ruby-gnome2.osdn.jp/ — https://github.com/ruby-gnome/ruby-gnome/tree/master/gstreamer/

  # Documents
  spec.add_dependency 'hexapdf', '~> 0.13'  # https://github.com/gettalong/hexapdf — https://hexapdf.gettalong.org/
  spec.add_dependency 'ffi-icu', '~> 0.3'  # https://github.com/erickguan/ffi-icu

  # Computer-y formats
  spec.add_dependency 'ttfunk', '~> 1.6'  # https://github.com/prawnpdf/ttfunk — https://prawnpdf.org/
end
