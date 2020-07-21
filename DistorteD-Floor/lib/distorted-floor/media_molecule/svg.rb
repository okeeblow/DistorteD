require 'set'

require 'mime/types'
require 'svg_optimizer'

module Cooltrainer
  module DistorteD
    class SVG < Image

      SUB_TYPE = 'svg'.freeze

      MIME_TYPES = MIME::Types[/^#{self::MEDIA_TYPE}\/#{self::SUB_TYPE}/, :complete => true].to_set

      def self.optimize(src, dest)
        # TODO: Make optimizations/plugins configurable
        SvgOptimizer.optimize_file(src, dest, SvgOptimizer::DEFAULT_PLUGINS)
      end

    end
  end
end
