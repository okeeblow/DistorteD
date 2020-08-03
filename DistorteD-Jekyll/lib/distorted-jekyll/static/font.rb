require 'fileutils'
require 'set'

require 'distorted/molecule/font'
require 'distorted-jekyll/static/text'


module Jekyll
  module DistorteD
    module Static
      class Font < Text

        DRIVER = Cooltrainer::DistorteD::Font

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

          @distorted = DRIVER.new(
            path,
            demo: attr_value(:title),
          )
          FileUtils.cp(path, File.join(dd_dest(dest), @name))

          super

        end

      end  # Text
    end  # Static
  end  # DistorteD
end  # Jekyll
