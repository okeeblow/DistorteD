require 'fileutils'
require 'set'

require 'distorted/molecule/text'
require 'distorted-jekyll/static/image'


module Jekyll
  module DistorteD
    module Static
      class Text < Image

        DRIVER = Cooltrainer::DistorteD::Text

        MEDIA_TYPE = DRIVER::MEDIA_TYPE
        MIME_TYPES = DRIVER::MIME_TYPES

        ATTRS = DRIVER::ATTRS
        ATTRS_DEFAULT = DRIVER::ATTRS_DEFAULT
        ATTRS_VALUES = DRIVER::ATTRS_VALUES


        # dest: String realpath to `_site` directory
        def write(dest)
          orig_dest = destination(dest)

          return false if !modified?
          self.class.mtimes[path] = mtime

          unless defined? @distorted
            @distorted = DRIVER.new(
              path,
              encoding: attr_value(:encoding),
              font: attr_value(:font),
              spacing: attr_value(:spacing),
              dpi: attr_value(:dpi),
            )
          end
          # Write any actual-text output variations.
          # Images will be written by `super`.
          for variation in files
            if DRIVER::MIME_TYPES.include?(variation&.dig(:type))
              filename = File.join(dd_dest(dest), variation&.dig(:name) || @name)
              Jekyll.logger.debug('DistorteD Writing:', filename)
              # TODO: For now this is just copying the file, but we should
              # probably support some sort of UTF conversion or something here.
              FileUtils.cp(path, filename)
            end
          end

          super

        end

      end  # Text
    end  # Static
  end  # DistorteD
end  # Jekyll
