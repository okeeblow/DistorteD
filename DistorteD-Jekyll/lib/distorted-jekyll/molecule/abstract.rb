require 'set'

require 'distorted-jekyll/floor'

require 'jekyll'
require 'liquid/errors'
require 'liquid/template'

require 'distorted/checking_you_out'


module Jekyll
  module DistorteD
    module Molecule
      module Abstract

        # This list should contain global attributes only, as symbols.
        # The final attribute set will be this + the media-type-specific set.
        # https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes
        GLOBAL_ATTRS = Set[:title]
        CONFIG_ATTRS = Set[:lower_world, :changes, :outer_limits]


        # Returns a Set of Arrays of search keys to try in config()
        def search_keys(*keys)
          # It's likely that we will get a default argument of [nil]
          # here due to the output of abstract(:whatever) for unset attrs.
          keys = keys.compact
          # If a search key path was given, construct one based
          # on the MIME::Type union Set between the source media
          # and the plugged MediaMolecule.
          if keys.empty? or keys.all?{|k| k.nil?}
            try_keys = @mime.map{ |t|
              # Use only the first part of complex sub_types like 'svg+xml'
              [t.media_type, t.sub_type.split('+').first].compact
            }
          else
            # Or use a user-provided config path.
            try_keys = Set[keys]
          end
        end

        # Loads configuration data telling us how to open certain
        # types of files.
        def welcome(*keys)
          # Try each set of keys until we find a match
          for try in search_keys(*keys)
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
        def changes(*keys)
          out = Set[]
          # `changes` media-type[sub_type] config will contain information about
          # what variations output format are desired for what input format,
          # e.g. {:image => {:jpeg => Set['image/jpeg', 'image/webp']}}
          # It is not automatically implied that the source format is also
          # an output format!
          for try in search_keys(*keys)
            tried = Jekyll::DistorteD::Floor::config(
            Jekyll::DistorteD::Floor::CONFIG_ROOT,
              :changes,
              *try,
            )
            if tried.is_a?(Enumerable) and tried.all?{|t| t.is_a?(String)} and not tried.empty?
              tried.each{ |t|
                # MIME::Type.new() won't give us a usable Type object:
                #
                # irb> MIME::Types['image/svg+xml'].first.preferred_extension
                # => "svg"
                # irb> MIME::Type.new('image/svg+xml').preferred_extension
                # => nil
                out.merge(CHECKING::YOU::IN(t))
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
          out = Set[]
          # See if any config data exists for each given key hierarchy,
          # but under the root DistorteD config key.
          for try in search_keys(*keys)
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

          # We should output something if the config didn't give us anything.
          # This is kind of a mess right now with redundancies in the call sites
          # of things like Molecule::Image. I'll come up with a better general-
          # purpose fallback solution at some point, but for now this will get
          # non-Image StaticFiles working with no config :)
          if out.empty?
            out << {
              :tag => :full,
            }
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
        def abstract(attribute)
          # Set of all supported attributes:
          # - Global output-element attributes
          # - Molecule-specific output-element attributes
          # - Filetype change and output-template config paths
          accepted_attrs = Set[]
          Set[:GLOBAL_ATTRS, :ATTRS, :CONFIG_ATTRS].each{ |a|
            if self.singleton_class.const_defined?(a)
              accepted_attrs.merge(self.singleton_class.const_get(a))
            end
          }

          # Set of acceptable values for the given attribute, e.g. Image::loading => Set[:eager, :lazy]
          # Will be empty if this attribute takes freeform input (like `title` or `alt`)
          accepted_vals = self.singleton_class.const_defined?(:ATTRS_VALUES) ?
                          self.singleton_class.const_get(:ATTRS_VALUES)&.dig(attribute) : Set[]

          # The value, if any, provided to our Liquid tag for this attr.
          liquid_val = attrs&.dig(attribute)

          # Is the requested attribute name defined as an accepted attribute
          # either globally or within the plugged MediaMolecule?
          if accepted_attrs.include?(attribute.to_sym)

            # Does this attr define a set of acceptable values?
            if accepted_vals.is_a?(Set)
              # Yes, it does. Is the Liquid-given value in that Set of acceptable values?
              if accepted_vals.include?(liquid_val) or accepted_vals.include?(liquid_val&.to_sym) or accepted_vals.include?(liquid_val&.to_s)

                # Yes, it is! Use it.
                liquid_val.to_s
              else
                # No, it isn't. Warn and return the default.
                unless liquid_val.nil?
                  Jekyll.logger.warn('DistorteD', "#{liquid_val.to_s} is not an acceptable value for #{attribute.to_s}: #{accepted_vals}")
                end
                if self.singleton_class.const_defined?(:ATTRS_DEFAULT)
                  self.singleton_class.const_get(:ATTRS_DEFAULT)&.dig(attribute).to_s
                else
                  # TODO: Raise custom error
                end
              end
            elsif accepted_vals.is_a?(Regexp)
              if accepted_vals =~ liquid_val.to_s
                Jekyll.logger.warn('DistorteD', "#{liquid_val.to_s} is a Regexp match for #{attribute.to_s}: #{accepted_vals}")
                liquid_val.to_s
              else
                unless liquid_val.nil?
                  Jekyll.logger.warn('DistorteD', "#{liquid_val.to_s} is not a Regexp match for #{attribute.to_s}: #{accepted_vals}")
                end
                self.singleton_class.const_get(:ATTRS_DEFAULT)&.dig(attribute)
              end
            else
              # No, this attribute does not define a Set of acceptable values.
              # The freeform Liquid-given value is fine, but if it's nil
              # we can still try for a default.
              if liquid_val.nil?
                self.singleton_class.const_get(:ATTRS_DEFAULT)&.dig(attribute)
              else
                liquid_val
              end
            end
          else
            Jekyll.logger.error('DistorteD', "#{attribute.to_s} is not a supported attribute")
            nil
          end
        end

        # Returns a Hash keyed by MIME::Type objects with value as a Set of Hashes
        # describing the media's output variations to be generated for each Type.
        def variations
          changes(abstract(:changes)).map{ |t|
            [t, outer_limits(abstract(:outer_limits)).map{ |d|

              # Don't change the filename of full-size variations
              tag = d&.dig(:tag) != :full ? '-'.concat(d&.dig(:tag).to_s) : ''.freeze
              # Use the original extname for LastResort
              ext = t == CHECKING::YOU::OUT('application/x.distorted.last-resort') ? File.extname(@name) : t.preferred_extension
              # Handle LastResort for files that might be a bare name with no extension
              dot = '.'.freeze unless ext.nil? || ext&.empty?

              d.merge({
                # e.g. 'SomeImage-medium.jpg` but just `SomeImage.jpg` and not `SomeImage-full.jpg`
                # for the full-resolution outputs.
                # The default `.jpeg` preferred_extension is monkey-patched to `.jpg` because lol
                :name => "#{basename}#{tag}#{dot}#{ext}",
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


      end  # Abstract
    end  # Molecule
  end  # DistorteD
end  # Jekyll
