# Tell the user to install the shared library if it's missing.
begin
  require 'gstreamer'
rescue LoadError => le
  # Only match libvips.so load failure
  raise unless le.message =~ /libvips.so/

  # Multiple OS help
  help = <<~INSTALL

  Please install the library.
  INSTALL

  # Re-raise with install message
  raise $!, "#{help}\n#{$!}", $!.backtrace
end

require 'formats/static_state'

module Jekyll
  # Tag-specific StaticFile child that handles thumbnail generation.
  class DistorteD::VideoFile < Jekyll::StaticState

    def initialize(
      site,
      base,
      dir,
      name,
      url,
      collection = nil
    )
      super 
    end


    # dest: string realpath to `_site_` directory
    def write(dest)
      orig_dest = destination(dest)
      return false if File.exist?(orig_path) && !modified?

      self.class.mtimes[path] = mtime

      FileUtils.mkdir_p(File.dirname(orig_dest))
      FileUtils.rm(orig_dest) if File.exist?(orig_dest)

      #orig = Vips::Image.new_from_file orig_path


      true
    end

  end
end
