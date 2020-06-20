require 'distorted-jekyll/error_code'
require 'distorted-jekyll/floor'
require 'distorted-jekyll/molecule/image'
require 'distorted-jekyll/molecule/video'
require 'liquid/tag'
require 'liquid/tag/parser'
require 'mime/types'
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
      ATTRS = Set[:title]

      def initialize(tag_name, arguments, liquid_options)
        super
        # Tag name as given to Liquid::Template.register_tag().
        # Yes, this is redundant considering this same file defines the name.
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
          Jekyll.logger.debug(@tag_name, @mime)
          if not (@mime & molecule.const_get(:MIME_TYPES)).empty?
            Jekyll.logger.debug(@tag_name, "Enabling #{molecule} for #{@name}: #{@mime & molecule.const_get(:MIME_TYPES)}")

            # Override Invoker's stubs by prepending the driver's methods to our DD instance's singleton class.
            # https://devalot.com/articles/2008/09/ruby-singleton
            # `self.singleton_class.extend(molecule)` doesn't work in this context.
            self.singleton_class.instance_variable_set(:@media_molecule, molecule)
            (class <<self; prepend @media_molecule; end)

            # Break out of the `loop`, a.k.a. stop auto-plugging!
            break
          end

        end

        # Set instance variables for the combined set of HTML element
        # attributes used for this media_type. The global set is defined in this file
        # (Invoker), and the media_type-specific set is appended to that during auto-plug.
        # TODO: Handle missing/malformed tag arguments.
        for attr in self.class::ATTRS
          attr_v = parsed_arguments[attr]
          Jekyll.logger.debug(@tag_name, "Setting attr #{attr.to_s} to #{attr_v}")
          instance_variable_set('@' + attr.to_s, parsed_arguments[attr])
        end
      end

      # Top-level media-type config will contain onformation about what variations in
      # output resolution, "pretty" name for those, CSS media query for
      # that variation, etc.
      def dimensions
        config(self.singleton_class.const_get(:MEDIA_TYPE))
      end

      # `changes` media-type[sub_type] config will contain information about
      # what variations output format are desired for what input format,
      # e.g. {:image => {:jpeg => Set['image/jpeg', 'image/webp']}}
      # It is not automatically implied that the source format is also
      # an output format!
      def types
        media_config = config(:changes, self.singleton_class.const_get(:CONFIG_SUBKEY))
        # The default config suggests disabling media_types by setting their
        # config key to `false`.
        if media_config.respond_to?(:empty?) and media_config.respond_to?(:key?)
          @mime.map { |m|
            media_config.dig(m.sub_type.to_sym)&.map { |d| MIME::Types[d] }
          }.flatten.to_set
        else
          Set[]
        end
      end

      def variations
        types.map{ |t| [t, full_dimensions.each{ |d| d }] }.to_h
      end

      def files
        filez = Set[]
        variations.each_pair{ |t,v|
          v.each{ |d|
            filez.add(d.merge({:name => "#{File.basename(@name, '.*')}-#{d[:tag]}.#{t.preferred_extension}"}))
          }
        }
        filez
      end

      #def filename(name, tag: nil, extension: nil)
      #  "#{File.basename(name)}#{if tag ; '-' << tag.to_s; else ''; end}.#{if extension; extension.to_s; else File.extname(name); end}"
      #end

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

      def render(context)
        # Get Jekyll Site object back from tag rendering context registers so we
        # can get configuration data and path information from it and
        # then pass it along to our StaticFile subclass.
        site = context.registers[:site]

        # The rendering context's `first` page will be the one that invoked us.
        page_data = context.environments.first['page']

        # Create an instance of the media-appropriate Jekyll::StaticFile subclass.
        #
        # StaticFile args:
        # site - The Jekyll Site object.
        # base - The String path to the Jekyll::Site#source - /home/okeeblow/cooltrainer
        # dir  - The String path between <base> and the file - _posts/2018-10-15-super-cool-post
        # name - The String filename - cool.jpg
        #
        # Our subclass' additional args:
        # dest - The String path to the generated `url` folder of the page HTML output
        base = site.source

        # `relative_path` doesn't seem to always exist, but `path` does? idk.
        # I was testing with `relative_path` only with `_posts`, but it broke
        # when I invoked DD on a _page. Both have `path`.
        dir = File.dirname(page_data['path'])

        # Every one of Ruby's `File.directory?` / `Pathname.directory?` /
        # `FileTest.directory?` methods actually tests that path on the
        # real filesystem, but we shouldn't look at the FS here because
        # this function gets called when the Site.dest directory does
        # not exist yet!
        # Hackily look at the last character to see if the URL is a
        # directory (like configured on cooltrainer) or a `.html`
        # (or other extension) like the default Jekyll config.
        # Get the dirname if the url is not a dir itself.
        @dd_dest = @url = page_data['url']
        unless @dd_dest[-1] == '/'
          @dd_dest = File.dirname(@dd_dest)
          # Append the trailing slash so we don't have to do it
          # in the Liquid templates.
          @dd_dest << '/'
        end

        @files = files
        static_file = self.static_file(site, base, dir, @name, @dd_dest, @url, full_dimensions, types, @files)

        # Don't force the StaticFile to re-detect the MIME::Types of its own file.
        static_file.instance_variable_set('@mime', instance_variable_get('@mime'))

        # Copy the merged Global + MEDIA_TYPE-appropriate attributes to the StaticFile.
        for attr in self.class::ATTRS
          Jekyll.logger.debug(@tag_name, "Setting attr #{attr.to_s} to #{instance_variable_get('@' + attr.to_s)}")
          static_file.instance_variable_set('@' + attr.to_s, instance_variable_get('@' + attr.to_s))
        end

        # Add our new file to the list that will be handled
        # by Jekyll's built-in StaticFile generator.
        # Our StaticFile children implement a write() that invokes DistorteD,
        # but this lets us avoid writing our own Generator.
        site.static_files << static_file
      end

      def parse_template(site = nil)
        site = site || Jekyll.sites.first
        begin
          # Template filename is based on the MEDIA_TYPE declared in the driver,
          # which will be set as an instance variable upon successful auto-plugging.
          template = File.join(File.dirname(__FILE__), 'template', "#{self.singleton_class.const_get(:MEDIA_TYPE)}.liquid")

          # Jekyll's Liquid renderer caches in 4.0+.
          # Make this a config option or get rid of it and always cache
          # once I have more experience with it.
          cache_templates = true
          if cache_templates
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
          l.message
        end
      end

      # Bail out if this is not handled by the module we just mixed in.
      def static_file(site, base, dir, name, dd_dest, url, dimensions, types, files)
        raise MediaTypeNotImplementedError.new(name)
      end
    end
  end
end
