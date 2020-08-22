require 'set'

require 'svg_optimizer'

require 'distorted/checking_you_out'


module Cooltrainer
  module DistorteD
    class SVG < Image

      SUB_TYPE = 'svg'.freeze

      LOWER_WORLD = CHECKING::YOU::IN(/^image\/svg/)

      def self.optimize(src, dest)
        # TODO: Make optimizations/plugins configurable
        SvgOptimizer.optimize_file(src, dest, SvgOptimizer::DEFAULT_PLUGINS)
      end

    end
  end
end
