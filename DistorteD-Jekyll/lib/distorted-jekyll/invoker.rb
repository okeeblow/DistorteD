# Our custom Exceptions
require 'distorted-jekyll/error_code'

# Configuration-loading code
require 'distorted-jekyll/floor'

# Configuration data manipulations
require 'distorted-jekyll/molecule/abstract'

# Media-type drivers
require 'distorted-jekyll/molecule/font'
require 'distorted-jekyll/molecule/image'
require 'distorted-jekyll/molecule/text'
require 'distorted-jekyll/molecule/pdf'
require 'distorted-jekyll/molecule/svg'
require 'distorted-jekyll/molecule/video'
require 'distorted-jekyll/molecule/last-resort'

# Set.to_hash
require 'distorted/monkey_business/set'

# Slip in and out of phenomenon
require 'liquid/tag'
require 'liquid/tag/parser'

# Explicitly required for l/t/parser since a1cfa27c27cf4d4c308da2f75fbae88e9d5ae893
require 'shellwords'

# Set is in stdlib but is not in core.
require 'set'

# MIME Magic 🧙‍♀️
require 'mime/types'
require 'ruby-filemagic'

# I mean, this is why we're here, right?
require 'jekyll'


module Jekyll
  module DistorteD
    class Invoker < Liquid::Tag

      GEM_ROOT = File.dirname(__FILE__).freeze

      # Mix in config-loading methods.
      include Jekyll::DistorteD::Molecule::Abstract

      # Enabled media_type drivers. These will be attempted back to front.
      # TODO: Make this configurable.
      MEDIA_MOLECULES = [
        Jekyll::DistorteD::Molecule::LastResort,
        Jekyll::DistorteD::Molecule::Font,
        Jekyll::DistorteD::Molecule::Text,
        Jekyll::DistorteD::Molecule::PDF,
        Jekyll::DistorteD::Molecule::SVG,
        Jekyll::DistorteD::Molecule::Video,
        Jekyll::DistorteD::Molecule::Image,
      ]

      # Any any attr value will get a to_sym if shorter than this
      # totally arbitrary length, or if the attr key is in the plugged
      # Molecule's set of attrs that take only a defined set of values.
      # My chosen boundary length fits all of the outer-limit tag names I use,
      # like 'medium'. It fits the longest value of Vips::Interesting too,
      # though `crop` will be symbolized based on the other condition.
      ARBITRARY_ATTR_SYMBOL_STRING_LENGTH_BOUNDARY = 13


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
        mime = MIME::Types.type_for(@name).to_set

        # We can't proceed without a usable media type.
        # Look at the actual file iff the filename wasn't enough to guess.
        unless mime.empty?
          Jekyll.logger.debug(@tag_name, "Detected #{@name} media types: #{mime}")
        else
          # Did we fail to guess any MIME::Types from the given filename?
          # We're going to have to look at the actual file
          # (or at least its first four bytes).
          # `@mime` will be readable/writable in the FileMagic.open block context
          # since it was already defined in the outer scope.
          FileMagic.open(:mime) do |fm|
            # TODO: Support finding files in paths deeper than the Site source.
            # There's no good way to get the path here of the Markdown file
            # that included our Tag, so relative paths won't work if given
            # as just a filename. It should work if supplied like:
            #   ![The coolest image ever](/2020/04/20/some-post/hahanofileextension)
            # This limitation is normally not a problem since we can guess
            # the MIME::Types just based on the filename.
            # It would be possible to supply the Markdown document's path
            # as an additional argument to {% distorted %} when converting
            # Markdown in `injection_of_love`, but I am resisting that
            # approach because it would make DD's Liquid and Markdown entrypoints
            # no longer exactly equivalent, and that's not okay with me.
            test_path = File.join(
              Jekyll::DistorteD::Floor::config(:source),
              Jekyll::DistorteD::Floor::config(:collections_dir),
              @name,
            )
            # The second argument makes fm.file return just the simple
            # MIME::Type String, e.g.:
            #
            # irb(main):006:1*   fm.file('/home/okeeblow/IIDX-turntable.svg')
            # => "image/svg+xml; charset=us-ascii"
            # irb(main):009:1*   fm.file('/home/okeeblow/IIDX-turntable.svg', true)
            # => "image/svg"
            #
            # However MIME::Types won't take short variants like 'image/svg',
            # so explicitly have FM return long types and split it ourself
            # on the semicolon:
            #
            # irb(main):038:0> "image/svg+xml; charset=us-ascii".split(';').first
            # => "image/svg+xml"
            mime = Set[MIME::Types[fm.file(@name, false).split(';'.freeze).first]]
          end

          # Did we still not get a type from FileMagic?
          unless mime
            if Jekyll::DistorteD::Floor::config(self.class.const_get(:CONFIG_ROOT), :last_resort)
              Jekyll.logger.debug(@tag_name, "Falling back to bare <img> for #{@name}")
              mime = Jekyll::DistorteD::Molecule::LastResort::MIME_TYPES
            else
              raise MediaTypeNotFoundError.new(@name)
            end
          end
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
          if molecule == nil
            if Jekyll::DistorteD::Floor::config(self.class.const_get(:CONFIG_ROOT), :last_resort)
              Jekyll.logger.debug(@tag_name, "Falling back to a bare <img> for #{name}")
              @mime = Jekyll::DistorteD::Molecule::LastResort::MIME_TYPES
              molecule = Jekyll::DistorteD::Molecule::LastResort
            else
              raise MediaTypeNotImplementedError.new(@name)
            end
          end

          Jekyll.logger.debug(@tag_name, "Trying to plug #{@name} into #{molecule}")

          # We found a potentially-compatible driver iff the union set is non-empty.
          if not (mime & molecule.const_get(:MIME_TYPES)).empty?
            @mime = mime & molecule.const_get(:MIME_TYPES)
            Jekyll.logger.debug(@tag_name, "Enabling #{molecule} for #{@name}: #{mime}")

            # Override Invoker's stubs by prepending the driver's methods to our DD instance's singleton class.
            # https://devalot.com/articles/2008/09/ruby-singleton
            # `self.singleton_class.extend(molecule)` doesn't work in this context.
            self.singleton_class.instance_variable_set(:@media_molecule, molecule)

            # Set instance variables for the combined set of HTML element
            # attributes used for this media_type. The global set is defined in this file
            # (Invoker), and the media_type-specific set is appended to that during auto-plug.
            attrs = (self.singleton_class.const_get(:GLOBAL_ATTRS) + molecule.const_get(:ATTRS)).to_hash
            attrs.each_pair do |attr, val|
              # An attr supplied to the Liquid tag should override any from the config
              liquid_val = parsed_arguments&.dig(attr)
              # nil.to_s is '', so print 'nil' for readability.
              Jekyll.logger.debug("Liquid #{attr}", liquid_val || 'nil')

              if liquid_val.is_a?(String)
                # Symbolize String values of any attr that has a Molecule-defined list
                # of acceptable values, or — completely arbitrarily — any String value
                # shorter than an arbitrarily-chosen constant.
                # Otherwise freeze them.
                if (liquid_val.length <= ARBITRARY_ATTR_SYMBOL_STRING_LENGTH_BOUNDARY) or
                    molecule.const_get(:ATTRS_VALUES).key?(attr)
                  liquid_val = liquid_val&.to_sym
                elsif liquid_val.length > ARBITRARY_ATTR_SYMBOL_STRING_LENGTH_BOUNDARY
                  # Will be default in Ruby 3.
                  liquid_val = liquid_val&.freeze
                end
              end

              attrs[attr] = liquid_val
            end

            # Save attrs to our instance as the data source for Molecule::Abstract.attrs.
            @attrs = attrs

            # Plug the chosen Media Molecule!
            # Using Module#prepend puts the Molecule's ahead in the ancestor chain
            # of any defined here, or any defined in an `include`d module.
            (class <<self; prepend @media_molecule; end)

            # Break out of the `loop`, a.k.a. stop auto-plugging!
            break
          end

        end
      end

      # Called by Jekyll::Renderer
      # https://github.com/jekyll/jekyll/blob/HEAD/lib/jekyll/renderer.rb
      # https://jekyllrb.com/tutorials/orderofinterpretation/
      def render(context)
        render_to_output_buffer(context, '')
      end

      # A future Liquid version (5.0?) will call this function directly
      # instead of calling render()
      def render_to_output_buffer(context, output)
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
        unless @dd_dest[-1] == Jekyll::DistorteD::Floor::PATH_SEPARATOR
          @dd_dest = File.dirname(@dd_dest)
          # Append the trailing slash so we don't have to do it
          # in the Liquid templates.
          @dd_dest << Jekyll::DistorteD::Floor::PATH_SEPARATOR
        end

        # Create an instance of the media-appropriate Jekyll::StaticFile subclass.
        #
        # StaticFile args:
        # site        - The Jekyll Site object.
        # base        - The String path to the Jekyll::Site.source, e.g. /home/okeeblow/Works/cooltrainer
        # dir         - The String path between <base> and the source file, e.g. _posts/2018-10-15-super-cool-post
        # name        - The String filename of the original media, e.g. cool.jpg
        # mime        - The Set of MIME::Types of the original media.
        # attrs       - The Set of attributes given to our Liquid tag, if any.
        # dd_dest     - The String path under Site.dest to DD's top-level media output directory.
        # url         - The URL of the page this tag is on.
        static_file = self.static_file(
          site,
          base,
          dir,
          @name,
          @mime,
          @attrs,
          @dd_dest,
          @url,
        )

        # Add our new file to the list that will be handled
        # by Jekyll's built-in StaticFile generator.
        # Our StaticFile children implement a write() that invokes DistorteD,
        # but this lets us avoid writing our own Generator.
        site.static_files << static_file
      end

      # Called by a Molecule-specific render() method since they will
      # all load their Liquid template files in the same way.
      # Bail out if this is not handled by the module we just mixed in.
      # Any media Molecule must override this to return an instance of
      # their media-type-appropriate StaticFile subclass.
      def static_file(site, base, dir, name, mime, attrs, dd_dest, url)
        raise MediaTypeNotImplementedError.new(name)
      end

      # Generic Liquid template loader that will be used in every MediaMolecule.
      # Callers will call `render(**{:template => vars})` on the Object returned
      # by this method.
      def parse_template(site: nil, name: nil)
        site = site || Jekyll.sites.first
        begin
          # Use a given filename, or detect one based on media-type.
          if name.nil?
            # Template filename is based on the MEDIA_TYPE and/or SUB_TYPE declared
            # in the plugged MediaMolecule for the given input file.
            if self.singleton_class.const_defined?(:SUB_TYPE)
              name = "#{self.singleton_class.const_get(:SUB_TYPE)}.liquid".freeze
            else
              name = "#{self.singleton_class.const_get(:MEDIA_TYPE)}.liquid".freeze
            end
          elsif not name.include?('.liquid'.freeze)
            # Support filename arguments with and without file extension.
            # The given String might already be frozen, so concatenating
            # the extension might fail. Just set a new version.
            name = "#{name}.liquid"
          end
          template = File.join(
            self.singleton_class.const_get(:GEM_ROOT),
            'template'.freeze,
            name,
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
            Jekyll.logger.debug('DistorteD', "Parsing #{template} with caching renderer.")
            site.liquid_renderer.file(template).parse(File.read(template))
          else
            # Re-read the template just for this piece of media.
            Jekyll.logger.debug('DistorteD', "Parsing #{template} with fresh (uncached) renderer.")
            Liquid::Template.parse(File.read(template))
          end

        rescue Liquid::SyntaxError => l
          # This shouldn't ever happen unless a new version of Liquid
          # breaks syntax compatibility with our templates somehow.
          l.message
        end
      end  # parse_template

    end
  end
end
