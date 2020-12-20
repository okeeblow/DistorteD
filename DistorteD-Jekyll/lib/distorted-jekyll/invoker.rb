# Our custom Exceptions
require 'distorted/error_code'

# Molecule loading and plugging functionality
require 'distorted/invoker'

# MIME::Typer
require 'distorted/checking_you_out'

# Configuration-loading code
require 'distorted-jekyll/the_setting_sun'
require 'distorted-jekyll/static_state'

# Slip in and out of phenomenon
require 'liquid/tag'
require 'liquid/tag/parser'

# Explicitly required for l/t/parser since a1cfa27c27cf4d4c308da2f75fbae88e9d5ae893
require 'shellwords'

# Set is in stdlib but is not in core.
require 'set'
# Set.to_hash
require 'distorted/monkey_business/set'

# I mean, this is why we're here, right?
require 'jekyll'


module Jekyll
  module DistorteD
    class Invoker < Liquid::Tag

      GEM_ROOT = File.dirname(__FILE__).freeze

      # Mix in config-loading methods.
      include Jekyll::DistorteD::Setting
      include Jekyll::DistorteD::StaticState

      # Load Jekyll Molecules which will implicitly load
      # the Floor Molecules they're based on.
      @@loaded_molecules rescue begin
        Dir[File.join(__dir__, 'molecule', '*.rb')].each { |molecule| require molecule }
        @@loaded_molecules = true
      end
      include Cooltrainer::DistorteD::Invoker

      # Enabled media_type drivers. These will be attempted back to front.
      def media_molecules
        Jekyll::DistorteD::Molecule.constants.map{ |molecule|
          Jekyll::DistorteD::Molecule::const_get(molecule)
        }
      end


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
          @name = parsed_arguments.delete(:src)
        else
          @name = parsed_arguments.delete(:argv1)
        end

        # Load contextual variables for abstract()
        @liquid_liquid = parsed_arguments.select{ |attr, val|
          not [nil, ''.freeze].include?(val)
        }.transform_keys(&:to_sym).transform_values { |val|
          case val
          when 'true' then true
          when 'false' then false
          when String then (val.length <= ARBITRARY_ATTR_SYMBOL_STRING_LENGTH_BOUNDARY) ? val.to_sym : val.freeze
          else val
          end
        }

        # If we didn't get one of the two above options there is nothing we
        # can do but bail.
        unless @name
          raise "Failed to get a usable filename from #{arguments}"
        end

      end

      # Returns a Set of DD MIME::Types descriving our file,
      # optionally falling through to a plain file copy.
      def type_mars
        @type_mars ||= (CHECKING::YOU::OUT(path, so_deep: true) & lower_world.keys.to_set).tap { |gemini|
          if gemini.empty? && the_setting_sun(:never_let_you_down)
            gemini << CHECKING::YOU::OUT['application/x.distorted.never-let-you-down']
          end
        }
        raise MediaTypeNotImplementedError.new(@name) if @type_mars.empty?
        @type_mars
      end

      # Returns an Array[Change] for every intended output variation
      def changes
        type_mars.reduce(Array[]) { |wanted, lower|
          # Handle empty sub_types by compacting and splatting a sub-Array
          config = the_setting_sun(:changes, *[lower.media_type, lower.sub_type.split('+').first].compact)
          config = (config.nil? || config&.empty?) ? Set[lower] : config.map {|t| CHECKING::YOU::OUT[t]}
          config.each { |t|
            vers = the_setting_sun(:outer_limits, *[t.media_type, t.sub_type.split('+').first].compact) || [{:tag=>:full, :crop=>:none}]
            wanted.concat(vers.map{ |v|
              Cooltrainer::Change.new(t, name: @name, **v)
            })
          }
          wanted
        }
      end

      # Return any arguments given by the user to our Liquid tag.
      # This method name is generic across all DD entrypoints so it can be
      # referenced from lower layers in the pile.
      def user_arguments
        @liquid_liquid || Hash[]
      end

      # Returns a context-only setting from our Liquid attributes.
      def abstract(key)
        user_arguments.dig(key)
      end

      # Called by Jekyll::Renderer
      # https://github.com/jekyll/jekyll/blob/HEAD/lib/jekyll/renderer.rb
      # https://jekyllrb.com/tutorials/orderofinterpretation/
      def render(context)
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
        unless @relative_dest[-1] == Jekyll::DistorteD::Setting::PATH_SEPARATOR
          @relative_dest = File.dirname(@relative_dest)
          # Append the trailing slash so we don't have to do it
          # in the Liquid templates.
          @relative_dest << Jekyll::DistorteD::Setting::PATH_SEPARATOR
        end

        # Duplicated from Floor Invoker#method_missing because all Molecules
        # share the same render_to_output_buffer method name for now,
        # so they won't be caught and plugged there like the Type-specific
        # file-writing methods.
        unless self.singleton_class.instance_variable_get(:@media_molecules)
          unless outer_limits.empty?
            self.singleton_class.instance_variable_set(
              :@media_molecules,
              outer_limits.keys.reduce(Set[]) { |molecules, molecule|
                self.singleton_class.prepend(molecule)
                molecules.add(molecule)
              }
            )
          end
        end

        # Add our new file to the list that will be handled
        # by Jekyll's built-in StaticFile generator.
        @site.static_files << self
        render_to_output_buffer(context, '')
      end

      # Generic Liquid template loader that will be used in every MediaMolecule.
      # Callers will call `render(**{:template => vars})` on the Object returned
      # by this method.
      def parse_template(site: nil, name: nil)
        site = site || @site || Jekyll.sites&.first
        begin
          # Use a given filename, or detect one based on media-type.
          if name.nil?
            # e.g. Jekyll::DistorteD::Molecule::Image -> 'image.liquid'
            name = "#{self.singleton_class.instance_variable_get(:@media_molecules).first.name.gsub(/^.*::/, '').downcase}.liquid".freeze
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
          if the_setting_sun(:remember_me)
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
