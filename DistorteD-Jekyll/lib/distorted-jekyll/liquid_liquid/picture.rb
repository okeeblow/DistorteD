require 'distorted-jekyll/liquid_liquid'
require 'distorted/modular_technology/vips/save'
require 'distorted/media_molecule'

module Jekyll; end
module Jekyll::DistorteD; end
module Jekyll::DistorteD::LiquidLiquid; end
module Jekyll::DistorteD::LiquidLiquid::Picture


  # Returns a CSS media query String for a full-size Image outer_limit allowing btowsers,
  # to properly consider its <source> alongside any generated resized versions of the same Image.
  # https://developer.mozilla.org/en-US/docs/Web/CSS/Media_Queries/Using_media_queries
  def self.full_size_media_query(change, vips_image)
    # This is kinda hacky, but use the Setting loader to look for `:outer_limits`
    # of this Type that are larger than this `vips_image` since we won't have visibility of
    # other `changes` from this Class instance method.
    larger_than_us = Jekyll::DistorteD::the_setting_sun(:outer_limits, *(change.type.settings_paths))
      .map { |l| l.fetch(:width, nil)}       # Look for a :width key in every outer limit.
      .compact                               # Discard any limits that don't define :width.
      .keep_if { |w| w > vips_image.width }  # Discard any limits whose :width is smaller than us.
    # Add an additional `max` constraint to the media query if this `vips_image`
    # is not the largest one in the <picture>.
    # This effectively makes this <source> useless since so few user-agents will ever
    # have a viewport the exact pixel width of this image, but for our use case
    # it's better to have a useless media query than no media query since it will
    # make browsers pick a better variation than this one.
    return "(min-width: #{vips_image.width}px)#{" and (max-width: #{vips_image.width}px)" unless larger_than_us.empty?}"
  end

  # Returns an anonymous method that generates a <source> tag for Image output Types.
  def self.render_picture_source
    @@render_picture_source = lambda { |change|
      # Fill in missing CSS media queries for any original-size (tag == null) Change that lacks one.
      if [:tag, :width, :media].map { |k| change.send(k) }.all?(&:nil?) and not change.type.sub_type.include?('svg'.freeze)
        change.media = Jekyll::DistorteD::LiquidLiquid::Picture::full_size_media_query(change, to_vips_image)
        change.width = to_vips_image.width
      end
      Cooltrainer::ElementalCreation.new(:picture_source, change, parents: Array[:anchor, :picture])
    }
  end

  # Lots of MediaMolecules will want to render image representations of various media_types,
  # so define a render method once for every Vips-supported Type that can be included/shared.
  Cooltrainer::DistorteD::IMPLANTATION(:OUTER_LIMITS, Cooltrainer::DistorteD::Technology::Vips::Save).each_key { |type|
    define_method(type.distorted_template_method, Jekyll::DistorteD::LiquidLiquid::Picture::render_picture_source)
  }

end
