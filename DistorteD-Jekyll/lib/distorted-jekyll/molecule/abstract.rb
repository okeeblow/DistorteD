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

        # Loads configuration data telling us how to open certain
        # types of files.
        def welcome(*keys)
          # Construct an Array of Arrays of config keys to search
          # based on the MIME::Type union Set between the source media
          # and the MediaMolecule.
          # Prepend the user-given search keys iff they aren't blank.
          try_keys = @mime.map{ |t|
            # Use only the first part of complex sub_types like 'svg+xml'
            [t.media_type, t.sub_type.split('+').first].compact
          }
          unless keys.empty?
            try_keys.unshift(keys)
          end

          # Try each set of keys until we find a match
          for try in try_keys
            tried = Jekyll::DistorteD::Floor::config(
              Jekyll::DistorteD::Floor::CONFIG_ROOT,
              :welcome,
              *try,
            )
            # Is the YAML config of the appropriate structure?
            if tried.is_a?(Hash)
              # Non-Hashes may not respond to `empty?`
              unless tried.empty?
                return tried
              end
            end
          end
        end

        # Load configuration telling us what media-types to generate
        # for any given media-type input.
        def changes
          out = Set[]

          # `changes` media-type[sub_type] config will contain information about
          # what variations output format are desired for what input format,
          # e.g. {:image => {:jpeg => Set['image/jpeg', 'image/webp']}}
          # It is not automatically implied that the source format is also
          # an output format!
          for m in @mime
            tried = Jekyll::DistorteD::Floor::config(
            Jekyll::DistorteD::Floor::CONFIG_ROOT,
              :changes,
              m.media_type,
              m.sub_type.split('+').first,
            )
            unless tried.nil?
              tried.each{ |t|
                # MIME::Type.new() won't give us a usable Type object:
                #
                # irb> MIME::Types['image/svg+xml'].first.preferred_extension
                # => "svg"
                # irb> MIME::Type.new('image/svg+xml').preferred_extension
                # => nil
                out.merge(MIME::Types[t])
              }
            end
          end

          # If the config didn't give us any MIME::Type changes
          # then we will just output the same type we loaded.
          if out.empty?
            return @mime
          else
            return out
          end
        end

        # Loads configuration telling us what variations to generate for any
        # given type of file, or for an arbitrary key hierarchy.
        def outer_limits(*keys)
          out = Set[
            # TODO: Make this configurable.
            # For now everything should output a full-size.
            {
              :tag => :full,
              :width => :full,
              :height => :full,
              :media => nil,
            }.merge(attrs).merge({:crop => :none})  # Never let `full` get cropped
          ]
          # Construct an Array of Arrays of config keys to search
          # based on the MIME::Type union Set between the source media
          # and the MediaMolecule.
          # Prepend the user-given search keys iff they aren't blank.
          try_keys = @mime.map{ |t|
            # Use only the first part of complex sub_types like 'svg+xml'
            [t.media_type, t.sub_type.split('+').first].compact
          }
          unless keys.empty?
            try_keys.unshift(keys)
          end

          # See if any config data exists for each given key hierarchy,
          # but under the root DistorteD config key.
          for try in try_keys
            tried = Jekyll::DistorteD::Floor::config(
              Jekyll::DistorteD::Floor::CONFIG_ROOT,
              :outer_limits,
              *try,
            )

            # Is the YAML config of the appropriate structure?
            # Merge a shallow copy of it with the Liquid-given attrs.
            # If we don't take a copy the attrs will be memoized into the config.
            if tried.is_a?(Enumerable) and tried.all?{|t| t.is_a?(Hash)} and not tried.empty?
              out.merge(tried.dup.map{ |d| d.merge(attrs) })
            end
          end

          return out
        end

        # Returns a Hash of any attribute provided to DD's Liquid tag and its value.
        def attrs
          # Value of every Molecule-defined attr will be nil if that attr
          # is not provided to our Liquid tag.
          @attrs.keep_if{|attr,val| val != nil}
        end

        # Returns the value for an attribute as given to the Liquid tag,
        # the default value if the given value is not in the accepted Set,
        # or nil for unset attrs with no default defined.
        def attr_value(attribute)
          # Set of all supported attributes both globally and Molecule-specific.
          accepted_attrs = self.class::GLOBAL_ATTRS + self.singleton_class.const_get(:ATTRS)

          # Set of acceptable values for the given attribute, e.g. Image::loading => Set[:eager, :lazy]
          # Will be empty if this attribute takes freeform input (like `title` or `alt`)
          accepted_vals = self.singleton_class.const_get(:ATTRS_VALUES)&.dig(attribute)

          # The value, if any, provided to our Liquid tag for this attr.
          liquid_val = attrs&.dig(attribute)

          # Is the requested attribute name defined as an accepted attribute
          # either globally or within the plugged MediaMolecule?
          if accepted_attrs.include?(attribute.to_sym)

            # Does this attr define a set of acceptable values?
            if accepted_vals
              # Yes, it does. Is the Liquid-given value in that Set of acceptable values?
              if accepted_vals.include?(liquid_val)
                # Yes, it is! Use it.
                liquid_val.to_s
              else
                # No, it isn't. Warn and return the default.
                Jekyll.logger.warn('DistorteD', "#{liquid_val.to_s} is not an acceptable value for #{attribute.to_s}: #{accepted_vals}")
                self.singleton_class.const_get(:ATTRS_DEFAULT)&.dig(attribute).to_s
              end
            else
              # No, this attribute does not define a Set of acceptable values.
              # The freeform Liquid-given value is fine.
              liquid_val.to_s
            end
          else
            Jekyll.logger.error('DistorteD', "#{attribute.to_s} is not a supported attribute")
            nil
          end
        end

        # Returns a Hash keyed by MIME::Type objects with value as a Set of Hashes
        # describing the media's output variations to be generated for each Type.
        def variations
          changes.map{ |t|
            [t, outer_limits.map{ |d|
              d.merge({
                # e.g. 'SomeImage-medium.jpg` but just `SomeImage.jpg` and not `SomeImage-full.jpg`
                # for the full-resolution outputs.
                # The default `.jpeg` preferred_extension is monkey-patched to `.jpg` because lol
                :name => "#{File.basename(@name, '.*')}#{'-'.concat(d[:tag].to_s) if d[:tag] != :full}.#{t.preferred_extension}",
              })
            }]
          }.to_h
        end

        # Returns a flat Set of Hashes that each describe one variant of
        # media file output that should exist for a given input file.
        def files
          filez = Set[]
          variations.each_pair{ |t,v|
            # Merge the type in to each variation Hash since we will no longer
            # have it as the key to this Set in its container Hash.
            v.each{ |d| filez.add(d.merge({:type => t})) }
          }
          filez
        end

        # Returns a Set of just the String filenames we want for this media.
        # This will be used by `modified?` among others.
        def filenames
          files.map{|f| f[:name]}.to_set
        end

        # Generic Liquid template loader that will be used in every MediaMolecule.
        # Callers will call `render(**{:template => vars})` on the Object returned
        # by this method.
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
            if Jekyll::DistorteD::Floor::config(
                Jekyll::DistorteD::Floor::CONFIG_ROOT,
                :cache_templates,
            )
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
    end  # Molecule
  end  # DistorteD
end  # Jekyll
