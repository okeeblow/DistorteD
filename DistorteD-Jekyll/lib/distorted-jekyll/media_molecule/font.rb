require 'set'

require 'distorted-jekyll/molecule/text'
require 'distorted-jekyll/static/font'

module Jekyll
  module DistorteD
    module Molecule
      module Font

        include Text

        DRIVER = Cooltrainer::DistorteD::Font

        MEDIA_TYPE = DRIVER::MEDIA_TYPE
        MIME_TYPES = DRIVER::MIME_TYPES

        ATTRS = DRIVER::ATTRS
        ATTRS_DEFAULT = DRIVER::ATTRS_DEFAULT
        ATTRS_VALUES = DRIVER::ATTRS_VALUES


        def static_file(*args)
          Jekyll::DistorteD::Static::Font.new(*args)
        end
      end  # Font
    end  # Molecule
  end  # DistorteD
end  # Jekyll
