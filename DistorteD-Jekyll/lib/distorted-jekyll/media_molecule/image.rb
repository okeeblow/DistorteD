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

module Jekyll
  # Tag-specific StaticFile child that handles thumbnail generation.
  class DistorteDImage < Jekyll::StaticFile
    def initialize(
        site,
        base,
        dir,
        name,
        dest,
        collection = nil
    )
      @tag_name = self.class.name.split('::').last
      Jekyll.logger.debug(@tag_name, "base is #{base}")
      Jekyll.logger.debug(@tag_name, "dir is #{dir}")
      Jekyll.logger.debug(@tag_name, "name is #{name}")
      Jekyll.logger.debug(@tag_name, "dest is #{dest}")
      @base = base
      @dir = dir
      @name = name
      @dest = dest
      # Constructor args for Jekyll::StaticFile:
      # site - The Jekyll Site object
      # base - The String path to the generated `_site` directory.
      # dir  - The String path for generated images, aka the page URL.
      # name - The String filename for one generated or original image.
      super(
        site,
        base,
        dir,
        name
      )

      @dimensions = site.config['distorted']['image']

      # Tell Jekyll we modified this file so it will be included in the output.
      @modified = true
      @modified_time = Time.now
    end

    # dest: string realpath to `_site_` directory
    def destination(dest, suffix = nil)
      File.join(@dest, Cooltrainer::DistortedFloor::image_name(@name, suffix))
    end

    # dest: string realpath to `_site_` directory
    def write(dest)
      Jekyll.logger.debug(@tag_name, "Writing filez to #{dest}")
      orig_dest = destination(dest)
      return false if File.exist?(orig_path) && !modified?

      self.class.mtimes[path] = mtime

      FileUtils.mkdir_p(File.dirname(orig_dest))
      FileUtils.rm(orig_dest) if File.exist?(orig_dest)

      orig = Vips::Image.new_from_file orig_path

      Jekyll.logger.debug(@tag_name, "Rotating #{@name} if tagged.")
      orig = orig.autorot

      # Nuke the entire site from orbit. It's the only way to be sure.
      orig.get_fields.grep(/exif-ifd/).each {|field| orig.remove field}

      orig.write_to_file orig_dest

      for d in @dimensions
        ver_dest = destination(dest, d['tag'])
        Jekyll.logger.debug(@tag_name, "Writing #{d['width']}px version to #{ver_dest}")
        ver = orig.thumbnail_image(d['width'])
        ver.write_to_file ver_dest
      end

      true
    end

    def modified?
      return true
    end

    def orig_path
      File.join(@base, @dir, @name)
    end
  end
end
