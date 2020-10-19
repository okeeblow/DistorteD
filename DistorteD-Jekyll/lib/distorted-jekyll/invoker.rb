# Our custom Exceptions
require 'distorted/error_code'

# MIME::Typer
require 'distorted/checking_you_out'

# Configuration-loading code
require 'distorted-jekyll/floor'
require 'distorted-jekyll/static_state'

# Configuration data manipulations
require 'distorted-jekyll/molecule/abstract'

# Media-type drivers
require 'distorted-jekyll/molecule/font'
require 'distorted-jekyll/molecule/image'
require 'distorted-jekyll/molecule/text'
require 'distorted-jekyll/molecule/pdf'
require 'distorted-jekyll/molecule/svg'
require 'distorted-jekyll/molecule/video'
require 'distorted-jekyll/molecule/lastresort'

# Set.to_hash
require 'distorted/monkey_business/set'

# Slip in and out of phenomenon
require 'liquid/tag'
require 'liquid/tag/parser'

# Explicitly required for l/t/parser since a1cfa27c27cf4d4c308da2f75fbae88e9d5ae893
require 'shellwords'

# Set is in stdlib but is not in core.
require 'set'

# I mean, this is why we're here, right?
require 'jekyll'


module Jekyll
  module DistorteD
    class Invoker < Liquid::Tag

      GEM_ROOT = File.dirname(__FILE__).freeze

      # Mix in config-loading methods.
      include Jekyll::DistorteD::Molecule::Abstract
      include Jekyll::DistorteD::Floor
      include Jekyll::DistorteD::StaticState

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
      # Reduce the above to a Hash of Sets of MediaMolecules-per-Type, keyed by Type.
      TYPE_MOLECULES = MEDIA_MOLECULES.reduce(
        Hash.new{|hash, key| hash[key] = Set[]}
      ) { |types, molecule|
        if molecule.const_defined?(:LOWER_WORLD)
          molecule.const_get(:LOWER_WORLD).each { |t|
            types.update(t => Set[molecule]) { |k,o,n| o.merge(n) }
          }
        end
        types
      }

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

        # We can't proceed without a usable media type.
        # Guess MIME Magic from the filename. For example:
        # `distorted IIDX-Readers-Unboxing.jpg: [#<MIME::Type: image/jpeg>]`
        #
        # Types#type_for can return multiple possibilities for a filename.
        # For example, an XML file: [application/xml, text/xml].
        # TODO: Provide realpath here instead of just the name
        @mime = CHECKING::YOU::OUT(@name)
        if @mime.empty?
          if Jekyll::DistorteD::Floor::config(Jekyll::DistorteD::Floor::CONFIG_ROOT, :last_resort)
            @mime = Jekyll::DistorteD::Molecule::LastResort::LOWER_WORLD
          end
        end


        available_molecules = TYPE_MOLECULES.keys.to_set & @mime
        # TODO: Handle multiple molecules for the same file
        case available_molecules.length
        when 0
          raise MediaTypeNotImplementedError.new(@name)
        when 1
          molecule = TYPE_MOLECULES[available_molecules.first].first

          # Plug the chosen Media Molecule!
          # NOTE: This is before attr-handling because most of our attribute definitions
          # won't exist in the ancestor chain otherwise until we prepend!
          self.singleton_class.instance_variable_set(:@media_molecule, molecule)
          self.singleton_class.prepend(molecule)

          liquid_liquid = self.singleton_class.instance_variable_get(:@DistorteD)&.dig(:ATTRS)&.dup.to_hash
          liquid_liquid.each_pair do |attr, val|
            liquid_val = parsed_arguments&.dig(attr)

            if liquid_val.is_a?(String)
              # Symbolize String values of any attr that has a Molecule-defined list
              # of acceptable values, or — completely arbitrarily — any String value
              # shorter than an arbitrarily-chosen constant.
              # Otherwise freeze them.
              if (liquid_val.length <= ARBITRARY_ATTR_SYMBOL_STRING_LENGTH_BOUNDARY) or
                  molecule.singleton_class.const_get(:ATTRS_VALUES).key?(attr)
                liquid_val = liquid_val&.to_sym
              elsif liquid_val.length > ARBITRARY_ATTR_SYMBOL_STRING_LENGTH_BOUNDARY
                liquid_val = liquid_val&.freeze
              end
            end

            liquid_liquid[attr] = liquid_val
          end

          # Save attrs to our instance as the data source for Molecule::Abstract.attrs.
          @liquid_attrs = liquid_liquid

        else
          raise Exception.new('Currently unable to handle multiple possible molecules for a file.')
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
        @site = context.registers[:site]

        # The rendering context's `first` page will be the one that invoked us.
        page_data = context.environments.first['page'.freeze]

        #
        # Our subclass' additional args:
        # dest - The String path to the generated `url` folder of the page HTML output
        @base = @site.source

        # `relative_path` doesn't seem to always exist, but `path` does? idk.
        # I was testing with `relative_path` only with `_posts`, but it broke
        # when I invoked DD on a _page. Both have `path`.
        @dir = File.dirname(page_data['path'.freeze])

        # Every one of Ruby's `File.directory?` / `Pathname.directory?` /
        # `FileTest.directory?` methods actually tests that path on the
        # real filesystem, but we shouldn't look at the FS here because
        # this function gets called when the Site.dest directory does
        # not exist yet!
        # Hackily look at the last character to see if the URL is a
        # directory (like configured on cooltrainer) or a `.html`
        # (or other extension) like the default Jekyll config.
        # Get the dirname if the url is not a dir itself.
        @relative_dest = page_data['url'.freeze]
        unless @relative_dest[-1] == Jekyll::DistorteD::Floor::PATH_SEPARATOR
          @relative_dest = File.dirname(@relative_dest)
          # Append the trailing slash so we don't have to do it
          # in the Liquid templates.
          @relative_dest << Jekyll::DistorteD::Floor::PATH_SEPARATOR
        end

        # Add our new file to the list that will be handled
        # by Jekyll's built-in StaticFile generator.
        @site.static_files << self
      end

      # Generic Liquid template loader that will be used in every MediaMolecule.
      # Callers will call `render(**{:template => vars})` on the Object returned
      # by this method.
      def parse_template(site: nil, name: nil)
        site = site || @site || Jekyll.sites.first
        begin
          # Use a given filename, or detect one based on media-type.
          if name.nil?
            # e.g. Jekyll::DistorteD::Molecule::Image -> 'image.liquid'
            name = "#{self.singleton_class.instance_variable_get(:@media_molecule).name.gsub(/^.*::/, '').downcase}.liquid".freeze
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
