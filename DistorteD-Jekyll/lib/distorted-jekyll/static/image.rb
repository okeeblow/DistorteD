# Tell the user to install the shared library if it's missing.
begin
  require 'vips'
rescue LoadError => le
  # Only match libvips.so load failure
  raise unless le.message =~ /libvips.so/

  # Multiple OS help
  help = <<~INSTALL

  Please install the libvips image processing library.

  FreeBSD:
    pkg install graphics/vips

  macOS:
    brew install vips

  Debian/Ubuntu/Mint:
    apt install libvips libvips-dev
  INSTALL

  # Re-raise with install message
  raise $!, "#{help}\n#{$!}", $!.backtrace
end

require 'formats/static_state'

module Jekyll
  # Tag-specific StaticFile child that handles thumbnail generation.
  class DistorteD::ImageFile < Jekyll::StaticState

    def initialize(
      site,
      base,
      dir,
      name,
      url,
      collection = nil
    )
      super

      @dimensions = site.config['distorted']['image']
    end

    # dest: string realpath to `_site_` directory
    def write(dest)
      orig_dest = destination(dest)
      return false if File.exist?(orig_path) && !modified?

      self.class.mtimes[path] = mtime

      FileUtils.mkdir_p(File.dirname(orig_dest))
      FileUtils.rm(orig_dest) if File.exist?(orig_dest)

      orig = Vips::Image.new_from_file orig_path

      Jekyll.logger.info(@tag_name, "Crop setting is #{@crop}")
      Jekyll.logger.debug(@tag_name, "Rotating #{@name} if tagged.")
      orig = orig.autorot

      # Nuke the entire site from orbit. It's the only way to be sure.
      orig.get_fields.grep(/exif-ifd/).each {|field| orig.remove field}

      orig.write_to_file orig_dest

      for d in @dimensions
        ver_dest = destination(dest, d['tag'])
        Jekyll.logger.debug(@tag_name, "Writing #{d['width']}px version to #{ver_dest}")
        ver = orig.thumbnail_image(d['width'], {:crop => @crop&.to_sym || :attention})
        ver.write_to_file ver_dest
      end

      true
    end
  end
end
