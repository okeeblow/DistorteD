require 'fileutils'
require 'set'

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

          Jekyll.logger.debug(@tag_name, "Copying #{@name} to #{dd_dest(dest)}")
          FileUtils.cp(path, File.join(dd_dest(dest), @name))

          true
        end
        
      end
    end
  end
end
