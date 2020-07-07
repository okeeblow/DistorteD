require 'fileutils'
require 'set'

require 'svg_optimizer'

require 'distorted-jekyll/static/image'

module Jekyll
  module DistorteD
    module Static
      class SVG < Jekyll::DistorteD::Static::Image

        # dest: string realpath to `_site_` directory
        def write(dest)
          return false if File.exist?(path) && !modified?
          self.class.mtimes[path] = mtime

          # Create any directories to the depth of the intended destination.
          FileUtils.mkdir_p(dd_dest(dest))

          svg_dest_path = File.join(dd_dest(dest), @name)

          if true  # TODO: Make this configurable
            Jekyll.logger.debug(@tag_name, "Optimizing #{@name} and copying to #{dd_dest(dest)}")
            # TODO: Make optimizations/plugins configurable
            SvgOptimizer.optimize_file(path, svg_dest_path, SvgOptimizer::DEFAULT_PLUGINS)
          else
            Jekyll.logger.debug(@tag_name, "Copying #{@name} to #{dd_dest(dest)}")
            FileUtils.cp(path, svg_dest_path)
          end

          true
        end
        
      end
    end
  end
end
