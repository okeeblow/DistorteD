require 'set'

require 'distorted-jekyll/floor'

require 'jekyll'
require 'liquid/errors'
require 'liquid/template'
require 'mime/types'


module Jekyll
  module DistorteD
    module Molecule
      module Abstract

        # Top-level media-type config will contain onformation about what variations in
        # output resolution, "pretty" name for those, CSS media query for
        # that variation, etc.
        def dimensions
          # Override the variation's attributes with any given to the Liquid tag.
          # Add a generated filename key in the form of e.g. 'somefile-large.png'.
          dimensions = config(
            self.singleton_class.const_get(:CONFIG_ROOT),
            :outer_limits,
            self.singleton_class.const_get(:MEDIA_TYPE),
            failsafe: Set,
          )

          if dimensions.is_a?(Enumerable)
            out = dimensions.map{ |d| d.merge(attrs) }
          else
            # This handles boolean values of media_type keys, e.g. `video: false`.
            out = Set[]
          end
          out
        end

        # `changes` media-type[sub_type] config will contain information about
        # what variations output format are desired for what input format,
        # e.g. {:image => {:jpeg => Set['image/jpeg', 'image/webp']}}
        # It is not automatically implied that the source format is also
        # an output format!
        def types
          media_config = config(
            self.singleton_class.const_get(:CONFIG_ROOT),
            :changes,
            self.singleton_class.const_get(:CONFIG_SUBKEY),
            failsafe: Set,
          )
          if media_config.empty?
            @mime.keep_if{ |m|
              m.media_type == self.singleton_class.const_get(:MEDIA_TYPE)
            }
          else
            @mime.map { |m|
              media_config.dig(m.sub_type.to_sym)&.map { |d| MIME::Types[d] }
            }.flatten.to_set
          end
        end

        # Returns a Hash of any attribute provided to DD's Liquid tag.
        def attrs
          # We only need to care about attrs that were set in the tag,
          # a.k.a. those that are non-nil in value.
          @attrs.keep_if{|attr,val| val != nil}
        end

        # Returns the value for an attribute as given to the Liquid tag,
        # the default value if the given value is not in the accepted Set,
        # or nil for unset attrs with no default defined.
        def attr_or_default(attribute)
          # The instance var is set on the StaticFile in Invoker,
          # based on attrs provided to DD's Liquid tag.
          # It will be nil if there is no e.g. {:loading => 'lazy'} IAL on our tag.
          accepted_attrs = self.class::GLOBAL_ATTRS + self.singleton_class.const_get(:ATTRS)
          accepted_vals = self.singleton_class.const_get(:ATTRS_VALUES)&.dig(attribute)
          liquid_val = attrs&.dig(attribute)
          if accepted_attrs.include?(attribute.to_sym)
            if accepted_vals
              if accepted_vals.include?(liquid_val)
                liquid_val.to_s
              else
                self.singleton_class.const_get(:ATTRS_DEFAULT)&.dig(attribute).to_s
              end
            else
              liquid_val.to_s
            end
          else
            nil
          end
        end

        # Returns a Hash of Media-types to be generated and the Set of variations
        # to be generated for that Type.
        # Mix any attributes provided to the Liquid tag in to every Variation
        # in every Type.
        def variations
          types.map{ |t|
            [t, full_dimensions.map{ |d|
              d.merge({
                :name => "#{File.basename(@name, '.*')}-#{d[:tag]}.#{t.preferred_extension}",
              })
            }]
          }.to_h
        end

        # Returns a Set of every filename that will be generated.
        # Used for things like `StaticFile.modified?`
        def files
          filez = Set[]
          variations.each_pair{ |t,v|
            v.each{ |d| filez.add(d.merge({:type => t})) }
          }
          filez
        end

        # Returns a version of `dimensions` that includes instructions to
        # generate an unadulterated (e.g. by cropping) version of the
        # input media file.
        def full_dimensions
          Set[
            # There should be no problem with the position of this item in the
            # variations list since Vips#thumbnail_image doesn't modify
            # the original in place, but it makes the most sense to go
            # biggest (original) to smallest, so put this first.
            # TODO: Make this configurable.
            {:tag => :full, :width => :full, :height => :full, :media => nil}
          ].merge(dimensions)
        end

        def parse_template(site: nil)
          site = site || Jekyll.sites.first
          begin
            # Template filename is based on the MEDIA_TYPE declared in the driver,
            # which will be set as an instance variable upon successful auto-plugging.
            template = File.join(
              self.singleton_class.const_get(:GEM_ROOT),
              'template'.freeze,
              "#{self.singleton_class.const_get(:MEDIA_TYPE)}.liquid"
            )

            # Jekyll's Liquid renderer caches in 4.0+.
            if config(self.singleton_class.const_get(:CONFIG_ROOT), :cache_templates)
              # file(path) is the caching function, with path as the cache key.
              # The `template` here will be the full path, so no versions of this
              # gem should ever conflict. For example, right now during dev it's:
              # `/home/okeeblow/Works/DistorteD/lib/image.liquid`
              site.liquid_renderer.file(template).parse(File.read(template))
            else
              # Re-read the template just for this piece of media.
              Liquid::Template.parse(File.read(template))
            end

          rescue Liquid::SyntaxError => l
            # This shouldn't ever happen unless a new version of Liquid
            # breaks syntax compatibility with our templates somehow.
            l.message
          end
        end


      end  # Abstract
    end  # 
  end  # DistorteD
end  # Jekyll
