# Our custom Exceptions
require 'distorted-jekyll/error_code'

# Configuration-handling code
require 'distorted-jekyll/floor'

# Media-type drivers
require 'distorted-jekyll/molecule/image'
require 'distorted-jekyll/molecule/video'

# Set.to_h
require 'distorted/monkey_business/set'

# Slip in and out of phenomenon
require 'liquid/tag'
require 'liquid/tag/parser'

# Explicitly required for l/t/parser since a1cfa27c27cf4d4c308da2f75fbae88e9d5ae893
require 'shellwords'

# MIME Magic 🧙‍♀️
require 'mime/types'

# I mean, this is why we're here, right?
require 'jekyll'


module Jekyll
  module DistorteD
    class Invoker < Liquid::Tag

      # Mix in config-loading methods.
      include Jekyll::DistorteD::Floor

      # Enabled media_type drivers. These will be attempted back to front.
      # TODO: Make this configurable.
      MEDIA_MOLECULES = [Jekyll::DistorteD::Molecule::Video, Jekyll::DistorteD::Molecule::Image]

      # This list should contain global attributes only, as symbols.
      # The final attribute set will be this + the media-type-specific set.
      # https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes
      GLOBAL_ATTRS = Set[:title]

      # 𝘏𝘖𝘞 𝘈𝘙𝘌 𝘠𝘖𝘜 𝘎𝘌𝘕𝘛𝘓𝘌𝘔𝘌𝘕 ！！
      def initialize(tag_name, arguments, liquid_options)
        super
        # Tag name as given to Liquid::Template.register_tag().
        @tag_name = tag_name.to_sym

        # Liquid leaves argument parsing totally up to us.
        # Use the envygeeks/liquid-tag-parser library to wrangle them.
        parsed_arguments = Liquid::Tag::Parser.new(arguments)

        # Filename is the only non-keyword argument our tag should ever get.
        # It's spe-shul and gets its own definition outside the attr loop.
        if parsed_arguments.key?(:src)
          @name = parsed_arguments[:src]
        else
          @name = parsed_arguments[:argv1]
        end

        # If we didn't get one of the two above options there is nothing we
        # can do but bail.
        unless @name
          raise "Failed to get a usable filename from #{arguments}"
        end

        # Guess MIME Magic from the filename. For example:
        # `distorted IIDX-Readers-Unboxing.jpg: [#<MIME::Type: image/jpeg>]`
        #
        # Types#type_for can return multiple possibilities for a filename.
        # For example, an XML file: [application/xml, text/xml].
        @mime = MIME::Types.type_for(@name).to_set

        # We can't proceed without a usable media type.
        if @mime
          Jekyll.logger.debug(@tag_name, "Detected #{@name} media types: #{@mime}")
        else
          raise MediaTypeNotFoundError.new(@name)
        end

        # Array of drivers to try auto-plugging. Take a shallow copy first because
        # these will get popped off the end for plug attempts.
        media_molecules = MEDIA_MOLECULES.dup

        ## Media Driver Autoplugging
        #
        # Take the union of this file's detected MIME::Types and
        # the supported MEDIA_TYPES declared in each molecule.
        # Molecules will likely declare their Types with a regex:
        # https://rdoc.info/gems/mime-types/MIME%2FTypes:[]
        #
        #
        # Still-Image Mime::Types Example:
        # MIME::Types.type_for('IIDX-Readers-Unboxing.jpg')
        # => [#<MIME::Type: image/jpeg>]
        #
        # Video MIME::Types Example:
        # MIME::Types.type_for('play.mp4') => [
        #   #<MIME::Type: application/mp4>,
        #   #<MIME::Type: audio/mp4>,
        #   #<MIME::Type: video/mp4>,
        #   #<MIME::Type: video/vnd.objectvideo>
        # ]
        #
        #
        # Molecule declared-supported MIME::Types Example:
        # (huge list)
        #   MIME_TYPES = MIME::Types[/^#{MEDIA_TYPE}/, :complete => true]
        #
        #
        # Detected & Declared MIME::Types Union Example:
        # MIME::Types.type_for('play.mp4') & MIME::Types[/^video/, :complete => true]
        # => [#<MIME::Type: video/mp4>, #<MIME::Type: video/vnd.objectvideo>]
        #
        # ^ This non-empty example union means we sould try this driver for this file.
        #
        #
        # Loop until we've found a match or tried all available drivers.
        loop do
          # Attempt to plug the last driver in the array of enabled drivers.
          molecule = media_molecules.pop

          # This will be nil once we've tried them all and run out and are on the last loop.
          # TODO: Support optional fall-through when plugging fails.
          if molecule == nil
            raise MediaTypeNotImplementedError.new(@name)
          end

          Jekyll.logger.debug(@tag_name, "Trying to plug #{@name} into #{molecule}")

          # We found a potentially-compatible driver iff the union set is non-empty.
          if not (@mime & molecule.const_get(:MIME_TYPES)).empty?
            Jekyll.logger.debug(@tag_name, "Enabling #{molecule} for #{@name}: #{@mime & molecule.const_get(:MIME_TYPES)}")

            # Override Invoker's stubs by prepending the driver's methods to our DD instance's singleton class.
            # https://devalot.com/articles/2008/09/ruby-singleton
            # `self.singleton_class.extend(molecule)` doesn't work in this context.
            self.singleton_class.instance_variable_set(:@media_molecule, molecule)

            # Set instance variables for the combined set of HTML element
            # attributes used for this media_type. The global set is defined in this file
            # (Invoker), and the media_type-specific set is appended to that during auto-plug.
            # TODO: Handle missing/malformed tag arguments.
            # NOTE: Relying on our own implementation of Set.to_h here.
            attrs = (self.class::GLOBAL_ATTRS + molecule.const_get(:ATTRS)).to_h
            attrs.each_pair do |attr, val|
              # An attr supplied to the Liquid tag should override any from the config
              liquid_val = parsed_arguments&.dig(attr)&.to_sym

              # Does this attribute have a Molecule-defined list of acceptable values?
              if molecule.const_get(:ATTRS_VALUES).key?(attr)
                # And if so, is the given value valid?
                if molecule.const_get(:ATTRS_VALUES)&.dig(attr).include?(liquid_val)
                  attrs[attr] = liquid_val
                  Jekyll.logger.debug(@tag_name, "Setting attr '#{attr.to_s}' to '#{liquid_val}' from Liquid tag.")
                end
              else
                # This Molecule doesn't define a list of accepted values for this attr,
                # so directly use what was supplied.
                attrs[attr] = liquid_val
              end
            end
            @attrs = attrs
            (class <<self; prepend @media_molecule; end)

            # Break out of the `loop`, a.k.a. stop auto-plugging!
            break
          end

        end
      end

      # Top-level media-type config will contain onformation about what variations in
      # output resolution, "pretty" name for those, CSS media query for
      # that variation, etc.
      def dimensions
        # Override the variation's attributes with any given to the Liquid tag.
        # Add a generated filename key in the form of e.g. 'somefile-large.png'.
        dimensions = config(self.singleton_class.const_get(:MEDIA_TYPE), failsafe: Set)

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
        media_config = config(:changes, self.singleton_class.const_get(:CONFIG_SUBKEY), failsafe: Set)
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

      # Called by Jekyll::Renderer
      # https://github.com/jekyll/jekyll/blob/HEAD/lib/jekyll/renderer.rb
      # https://jekyllrb.com/tutorials/orderofinterpretation/
      def render(context)
        # Get Jekyll Site object back from tag rendering context registers so we
        # can get configuration data and path information from it and
        # then pass it along to our StaticFile subclass.
        site = context.registers[:site]

        # The rendering context's `first` page will be the one that invoked us.
        page_data = context.environments.first['page'.freeze]

        #
        # Our subclass' additional args:
        # dest - The String path to the generated `url` folder of the page HTML output
        base = site.source

        # `relative_path` doesn't seem to always exist, but `path` does? idk.
        # I was testing with `relative_path` only with `_posts`, but it broke
        # when I invoked DD on a _page. Both have `path`.
        dir = File.dirname(page_data['path'.freeze])

        # Every one of Ruby's `File.directory?` / `Pathname.directory?` /
        # `FileTest.directory?` methods actually tests that path on the
        # real filesystem, but we shouldn't look at the FS here because
        # this function gets called when the Site.dest directory does
        # not exist yet!
        # Hackily look at the last character to see if the URL is a
        # directory (like configured on cooltrainer) or a `.html`
        # (or other extension) like the default Jekyll config.
        # Get the dirname if the url is not a dir itself.
        @dd_dest = @url = page_data['url'.freeze]
        unless @dd_dest[-1] == PATH_SEPARATOR
          @dd_dest = File.dirname(@dd_dest)
          # Append the trailing slash so we don't have to do it
          # in the Liquid templates.
          @dd_dest << PATH_SEPARATOR
        end

        # Create an instance of the media-appropriate Jekyll::StaticFile subclass.
        #
        # StaticFile args:
        # site        - The Jekyll Site object.
        # base        - The String path to the Jekyll::Site.source, e.g. /home/okeeblow/Works/cooltrainer
        # dir         - The String path between <base> and the source file, e.g. _posts/2018-10-15-super-cool-post
        # name        - The String filename of the original media, e.g. cool.jpg
        # mime        - The Set of MIME::Types of the original media.
        # dd_dest     - The String path under Site.dest to DD's top-level media output directory.
        # url         - The URL of the page this tag is on.
        # dimensions  - The Set of Hashes describing size variations to generate.
        # types       - The Set of MIME::Types to generate.
        # files       - The Set of Hashes describing files to be generated;
        #               a combination of `types` and `dimensions` but passed in
        #               instead of generated so Liquid template can share it too.
        static_file = self.static_file(
          site,
          base,
          dir,
          @name,
          @mime,
          @dd_dest,
          @url,
          full_dimensions,
          types,
          files,
        )

        # Add our new file to the list that will be handled
        # by Jekyll's built-in StaticFile generator.
        # Our StaticFile children implement a write() that invokes DistorteD,
        # but this lets us avoid writing our own Generator.
        site.static_files << static_file
      end

      # Called by a Molecule-specific render() method since they will
      # all load their Liquid template files in the same way.
      def parse_template(site: nil)
        site = site || Jekyll.sites.first
        begin
          # Template filename is based on the MEDIA_TYPE declared in the driver,
          # which will be set as an instance variable upon successful auto-plugging.
          template = File.join(
            File.dirname(__FILE__),
            'template'.freeze,
            "#{self.singleton_class.const_get(:MEDIA_TYPE)}.liquid"
          )

          # Jekyll's Liquid renderer caches in 4.0+.
          if config(:cache_templates)
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

      # Bail out if this is not handled by the module we just mixed in.
      # Any media Molecule must override this to return an instance of
      # their media-type-appropriate StaticFile subclass.
      def static_file(site, base, dir, name, dd_dest, url, dimensions, types, files)
        raise MediaTypeNotImplementedError.new(name)
      end
    end
  end
end
