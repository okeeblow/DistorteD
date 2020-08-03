require 'fileutils'
require 'set'

require 'distorted/molecule/pdf'
require 'distorted-jekyll/static/pdf'


module Jekyll
  module DistorteD
    module Static
      class PDF < Jekyll::DistorteD::Static::State

        DRIVER = Cooltrainer::DistorteD::PDF

        MEDIA_TYPE = DRIVER::MEDIA_TYPE
        SUB_TYPE = DRIVER::SUB_TYPE
        MIME_TYPES = DRIVER::MIME_TYPES

        ATTRS = DRIVER::ATTRS
        ATTRS_DEFAULT = DRIVER::ATTRS_DEFAULT
        ATTRS_VALUES = DRIVER::ATTRS_VALUES


        # dest: string realpath to `_site_` directory
        def write(dest)
          return false if File.exist?(path) && !modified?
          self.class.mtimes[path] = mtime

          # Create any directories to the depth of the intended destination.
          FileUtils.mkdir_p(dd_dest(dest))

          for variation in files
            if DRIVER::MIME_TYPES.include?(variation[:type])
              pdf_dest_path = File.join(dd_dest(dest), variation[:name])

              if true  # TODO: Make this configurable
                Jekyll.logger.debug(@tag_name, "Optimizing #{@name} and copying to #{dd_dest(dest)}")
                # TODO: Make optimizations/plugins configurable
                DRIVER::optimize(path, pdf_dest_path)
              else
                Jekyll.logger.debug(@tag_name, "Copying #{@name} to #{dd_dest(dest)}")
                FileUtils.cp(path, pdf_dest_path)
              end
            end
          end

          true
        end

      end  # PDF
    end  # Static
  end  # DistorteD
end  # Jekyll
