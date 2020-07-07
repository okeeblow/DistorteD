require 'mime/types'

module Cooltrainer
  class DistorteD
    class SVG < Image

      SUB_TYPE = 'svg'.freeze

      MIME_TYPES = MIME::Types[/^#{self::MEDIA_TYPE}\/#{self::SUB_TYPE}/, :complete => true].to_set

    end
  end
end
