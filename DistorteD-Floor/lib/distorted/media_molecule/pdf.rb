require 'set'

require 'hexapdf'
require 'mime/types'


module Cooltrainer
  class DistorteD
    class PDF

      MEDIA_TYPE = 'application'.freeze
      SUB_TYPE = 'pdf'.freeze

      MIME_TYPES = MIME::Types["#{MEDIA_TYPE}/#{SUB_TYPE}"].to_set

      # https://developer.mozilla.org/en-US/docs/Web/HTML/Element/object#Attributes
      ATTRS = Set[:alt, :caption, :height, :width]

      ATTRS_DEFAULT = {
        :height => '100%'.freeze,
        :width => '100%'.freeze,
      }
      ATTRS_VALUES = {}


      def self.optimize(src, dest)
        HexaPDF::Document.open(src) do |doc|
          doc.task(
            :optimize,
            compact: true,
            object_streams: :generate,
            xref_streams: :generate,
            compress_pages: false,
          )
          doc.write(dest)
        end
      end

    end  # PDF
  end  # DistorteD
end  # Cooltrainer
