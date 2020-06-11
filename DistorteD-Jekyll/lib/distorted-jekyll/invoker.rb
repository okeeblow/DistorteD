require 'distorted-jekyll/floor'
require 'distorted-jekyll/image'
require 'distorted-jekyll/video'
require 'liquid/tag'
require 'liquid/tag/parser'
require 'mime/types'

module Jekyll
  module DistorteD
    class Invoker < Liquid::Tag

      include Jekyll::DistorteD::Floor

      # The built-in NotImplementedError is for "when a feature is not implemented
      # on the current platform", so make our own more appropriate one.
      class MediaTypeNotImplementedError < StandardError
        attr_reader :media_type, :name
        def initialize(name)
          super("No supported media type for #{name}")
        end
      end

      # This list should contain global attributes only, as symbols.
      # The final attribute set will be this + the media-type-specific set.
      # https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes
      ATTRS = Set[:title]

      def initialize(tag_name, arguments, liquid_options)
        super
        # Tag name as given to Liquid::Template.register_tag().
        # Yes, this is redundant considering this same file defines the name.
        @tag_name = tag_name

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
        @mime = MIME::Types.type_for(@name)

        # We can't proceed without a usable media type.
        if @mime
          Jekyll.logger.debug(@tag_name, "#{@name}: #{@mime}")
        else
          raise "Failed to get a MIME type for #{@name}!"
        end

        # Activate media handler based on union of detected MIME Types and
        # the supported types declared in each handler.
        # Handlers will likely declare their Types with a regex:
        # https://rdoc.info/gems/mime-types/MIME%2FTypes:[]
        #
        # MIME::Types.type_for('IIDX-Readers-Unboxing.jpg')
        # => [#<MIME::Type: image/jpeg>]
        #
        # MIME::Types.type_for('play.mp4') => [
        #   #<MIME::Type: application/mp4>,
        #   #<MIME::Type: audio/mp4>,
        #   #<MIME::Type: video/mp4>,
        #   #<MIME::Type: video/vnd.objectvideo>
        # ]
        #
        # MIME::Types.type_for('play.mp4') & MIME::Types[/^video/, :complete => true]
        # => [#<MIME::Type: video/mp4>, #<MIME::Type: video/vnd.objectvideo>]
        #
        # Mix in known media_type handlers by prepending our singleton class
        # with the handler module, so module methods override ones defined here.
        # Also combine the handler module's tag attributes with the global ones.
        #
        # Note to self:
        # If you end up implementing some meta bullshit here do it with Module#const_get
        # http://blog.sidu.in/2008/02/loading-classes-from-strings-in-ruby.html

        if not (@mime & Jekyll::DistorteD::Image::MIME_TYPES).empty?
          Jekyll.logger.debug(@tag_name, @mime & Jekyll::DistorteD::Image::MIME_TYPES)
          self.class::ATTRS.merge(Jekyll::DistorteD::Image::ATTRS)
          @media_type = Jekyll::DistorteD::Image::MEDIA_TYPE
          (class <<self; prepend Jekyll::DistorteD::Image; end)
        elsif not (@mime & Jekyll::DistorteD::Video::MIME_TYPES).empty?
          Jekyll.logger.debug(@tag_name, @mime & Jekyll::DistorteD::Video::MIME_TYPES)
          self.class::ATTRS.merge(Jekyll::DistorteD::Video::ATTRS)
          @media_type = Jekyll::DistorteD::Video::MEDIA_TYPE
          (class <<self; prepend Jekyll::DistorteD::Video; end)
        else
          raise MediaTypeNotImplementedError.new(@media_type)
        end
        Jekyll.logger.debug(@tag_name, "Handling #{@name} as a(n) #{@media_type}")

        # Set instance variables for the combined set of global+handler tag
        # attributes used by this media_type.
        # TODO: Handle missing/malformed tag arguments.
        for attr in self.class::ATTRS
          Jekyll.logger.debug(@tag_name, "Setting attr #{attr.to_s} to #{parsed_arguments[attr]}")
          instance_variable_set('@' + attr.to_s, parsed_arguments[attr])
        end
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
        @url = page_data['url']

        # Instantiate the appropriate StaticFile subclass for any handler.
        static_file = self.static_file(site, base, dir, @name, @url)

        static_file.instance_variable_set('@mime', instance_variable_get('@mime'))

        # Copy the media attribute instance variable contents to the StaticFile.
        for attr in self.class::ATTRS
          Jekyll.logger.debug(@tag_name, "Setting attr #{attr.to_s} to #{instance_variable_get('@' + attr.to_s)}")
          static_file.instance_variable_set('@' + attr.to_s, instance_variable_get('@' + attr.to_s))
        end

        # Add our new file to the list that will be handled
        # by Jekyll's built-in StaticFile generator.
        site.static_files << static_file
      end

      def parse_template(site)
        begin
          template = File.join(File.dirname(__FILE__), 'templates', "#{@media_type}.liquid")

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
            Liquid::Template.parse(File.read(template))
          end

        rescue Liquid::SyntaxError => l
          l.message
        end
      end

      # Bail out if this is not handled by the module we just mixed in.
      def static_file(site, base, dir, name, url)
        raise MediaTypeNotImplementedError.new(name)
      end
    end
  end
end
