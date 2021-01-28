require 'distorted-jekyll/liquid_liquid'
require 'distorted/modular_technology/vips/save'
require 'distorted/media_molecule'

module Jekyll; end
module Jekyll::DistorteD; end
module Jekyll::DistorteD::LiquidLiquid; end
module Jekyll::DistorteD::LiquidLiquid::Picture


  # Our <picture> tag needs a child <img> tag to display an appropriate <source> into.
  # That <img> can be totally blank — <img/> — but we should fill it with a fallback
  # for browsers that don't support <picture> that will fall through to just rendering
  # the <img> and its `src`.
  # Browsers old enough to lack <picture> support almost certainly lack support
  # for newer Image Types like WebP/AVIF. Use a MetaType to trigger the selection
  # and rendering of one (1) fallback.
  FALLBACK_IMAGE_TYPE = CHECKING::YOU::OUT['image/x.distorted.fallback']
  OUTER_LIMITS = Hash[FALLBACK_IMAGE_TYPE => nil]

  # Given an input Change, what MIME::Type should we use as the fallback?
  def detect_fallback_image_type
    @fallback_image_type ||= case
    when to_vips_image.has_alpha? then CHECKING::YOU::OUT['image/png'.freeze]
    when to_vips_image.percent(100) <= 256 then CHECKING::YOU::OUT['image/gif'.freeze]
    else CHECKING::YOU::OUT['image/jpeg'.freeze]
    end
  end

  # Returns a modified copy of a Change that includes the new fallback Type and Tag
  def change_fallback_image(change)
    change_fallback_image!(change.dup)
  end

  # Returns a Change modified in-place to includ the new fallback Type and Tag
  def change_fallback_image!(change)
    change.tap { |change|
      change.type = detect_fallback_image_type
      change.tag = :fallback
    }
  end

  define_method(FALLBACK_IMAGE_TYPE.distorted_template_method) { |change|
    # TODO: Fix the interaction between Change#name and any Tags, stop modifying this Change
    # in-place since it will currently go on to run the modified-Type's :write method,
    # and stop regenerating all files when only one has changed.
    change_fallback_image!(change)
    Cooltrainer::ElementalCreation.new(:img, change, parents: Array[:anchor, :picture])
  }
  define_method(FALLBACK_IMAGE_TYPE.distorted_file_method) { |dest_root, change|
    # TODO: Handle `:modified?` more gracefully and stop relying on the above fallback
    # `:distorted_template_method` to modify our Change for us.
    # This currently never runs!
    self.send(detect_fallback_image_type.distorted_file_method, dest_root, change_fallback_image(change))
  }

  # Returns an anonymous method that generates a <source> tag for Image output Types.
  def self.render_picture_source
    @@render_picture_source = lambda { |change|
      # Fill in missing CSS media queries for any original-size (tag == null) Change that lacks one.
      if change.width.nil? and not change.type.sub_type.include?('svg'.freeze)
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
