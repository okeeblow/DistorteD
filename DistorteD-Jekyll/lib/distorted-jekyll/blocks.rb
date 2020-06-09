require 'distorted-jekyll/floor'

module Jekyll
  class BLOCKS < Liquid::Block

    include Jekyll::DistorteD::Floor

    def initialize(tag_name, arguments, liquid_options)
      super
    end

    def render(context)
      "<div class=\"distorted-grid\">#{super}</div>"
    end

  end
end
