require 'fileutils'
require 'set'


require 'distorted-jekyll/static/image'

module Jekyll
  module DistorteD
    module Static
      class SVG < Jekyll::DistorteD::Static::Image

        DRIVER = Cooltrainer::DistorteD::SVG

        # dest: string realpath to `_site_` directory
        def write(dest)
          return false if File.exist?(path) && !modified?
          self.class.mtimes[path] = mtime

          # Create any directories to the depth of the intended destination.
          FileUtils.mkdir_p(dd_dest(dest))

          for variation in files
            if DRIVER::MIME_TYPES.include?(variation[:type])
              svg_dest_path = File.join(dd_dest(dest), variation[:name])

              if true  # TODO: Make this configurable
                Jekyll.logger.debug(@tag_name, "Optimizing #{@name} and copying to #{dd_dest(dest)}")
                DRIVER::optimize(path, svg_dest_path)
              else
                Jekyll.logger.debug(@tag_name, "Copying #{@name} to #{dd_dest(dest)}")
                FileUtils.cp(path, svg_dest_path)
              end
            end
          end

          super  # Generate raster Image variations
          true
        end
        
      end
    end
  end
end
