require 'distorted/image'
require 'distorted-jekyll/static/state'

module Jekyll
  module DistorteD
    module Static
      class Image < Jekyll::DistorteD::Static::State

        # dest: string realpath to `_site_` directory
        def write(dest)
          return false if File.exist?(src_path) && !modified?
          self.class.mtimes[path] = mtime

          # Create any directories to the depth of the intended destination.
          fullres_dest = @dest
          FileUtils.mkdir_p(fullres_dest)

          distorted = Cooltrainer::DistorteD::Image.new(
            src_path,
            dest: fullres_dest,
            filenames: @filenames,
          )

          Jekyll.logger.debug(@tag_name, "Rotating #{@name} if tagged.")
          distorted.rotate(angle: :auto)

          distorted.types = @types
          distorted.dimensions = @dimensions

          Jekyll.logger.debug(@tag_name, "Adding dimensions #{distorted.dimensions}")

          distorted.generate

          true
        end

      end  # Image
    end  # Static
  end  # DistorteD
end  # Jekyll
