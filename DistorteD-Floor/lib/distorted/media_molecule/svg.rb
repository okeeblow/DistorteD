require 'set'

require 'svg_optimizer'

require 'distorted/checking_you_out'


module Cooltrainer
  module DistorteD
    class SVG < Image

      SUB_TYPE = 'svg'.freeze

      MIME_TYPES = CHECKING::YOU::IN(/^#{self::MEDIA_TYPE}\/#{self::SUB_TYPE}/)

      def self.optimize(src, dest)
        # TODO: Make optimizations/plugins configurable
        SvgOptimizer.optimize_file(src, dest, SvgOptimizer::DEFAULT_PLUGINS)
      end

    end
  end
end
