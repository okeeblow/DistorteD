require 'fileutils'
require 'set'

require 'distorted/image'
require 'distorted-jekyll/static/state'

module Jekyll
  module DistorteD
    module Static
      class Image < Jekyll::DistorteD::Static::State

        DRIVER = Cooltrainer::DistorteD::Image

        # dest: string realpath to `_site_` directory
        def write(dest)
          return false if File.exist?(path) && !modified?
          self.class.mtimes[path] = mtime

          # Create any directories to the depth of the intended destination.
          FileUtils.mkdir_p(dd_dest(dest))

          distorted = DRIVER.new(path)

          Jekyll.logger.debug(@tag_name, "Rotating #{@name} if tagged.")
          distorted.rotate(angle: :auto)

          # Save every desired variation of this image.
          # This will be a Set of Hashes each describing the name, type,
          # dimensions, attributes, etc of each output variation we want.
          # Full-size outputs will have the special tag `:full`.
          for variation in files
            if DRIVER::MIME_TYPES.include?(variation[:type])
              filename = File.join(dd_dest(dest), variation[:name])
              Jekyll.logger.debug('DistorteD Writing:', filename)
              distorted.save(filename, width: variation[:width], crop: variation[:crop])
            end
          end

          true
        end

      end  # Image
    end  # Static
  end  # DistorteD
end  # Jekyll
