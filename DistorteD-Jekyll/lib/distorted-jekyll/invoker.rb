# Our custom Exceptions
require 'distorted-floor/error_code'

# Molecule loading and plugging functionality
require 'distorted-floor/invoker'

# File Typer
require 'distorted-floor/checking_you_out'
using ::DistorteD::CHECKING::YOU::OUT

# Configuration-loading code
require 'distorted-jekyll/the_setting_sun'
require 'distorted-jekyll/static_state'

# Slip in and out of phenomenon
require 'liquid/tag'
require 'liquid/tag/parser'
require 'distorted-jekyll/liquid_liquid'

require 'distorted-jekyll/media_molecule'

# Explicitly required for l/t/parser since a1cfa27c27cf4d4c308da2f75fbae88e9d5ae893
require 'shellwords'

# Set is in stdlib but is not in core.
require 'set'
# Set.to_hash
require 'distorted-floor/monkey_business/set'

# I mean, this is why we're here, right?
require 'jekyll'


class Jekyll::DistorteD::Invoker < Liquid::Tag

  GEM_ROOT = File.dirname(__FILE__).freeze

  include Jekyll::DistorteD::Setting       # Config-loading methods.
  include Jekyll::DistorteD::StaticState   # Jekyll::StaticFile impersonation methods.
  include Cooltrainer::DistorteD::Invoker  # Instance-setup methods.


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
    @tag_arguments = parsed_arguments.select{ |attr, val|
      not [nil, ''.freeze].include?(val)
    }.transform_keys(&:to_sym).transform_values { |val|
      case val
      when 'true' then true
      when 'false' then false
      when String then (val.length <= Jekyll::DistorteD::ARBITRARY_ATTR_SYMBOL_STRING_LENGTH_BOUNDARY) ? val.to_sym : val.freeze
      else val
      end
    }

    # If we didn't get one of the two above options there is nothing we
    # can do but bail.
    unless @name
      raise "Failed to get a usable filename from #{arguments}"
    end

  end

  # Returns a `::Set` of `::CHECKING::YOU::OUT` objects describing our file,
  # optionally falling through to a plain file copy.
  def type_mars
    # TODO: Get rid of the redundant `Set[…].flatten` here once I stabilize CYO API.
    @type_mars ||= (Set[::CHECKING::YOU::OUT(path)].flatten & lower_world.keys.to_set).tap { |gemini|
      raise ArgumentError(gemini)
      if gemini.empty? && the_setting_sun(:never_let_you_down)
        gemini << ::CHECKING::YOU::OUT::from_iana_media_type('application/x.distorted.never-let-you-down')
      end
    }
    raise MediaTypeNotImplementedError.new(@name) if @type_mars.empty?
    @type_mars
  end

  # Returns an Array[Change] for every intended output Type
  # and every variation (e.g. resolution, bitrate) on each Type.
  def changes
    # The available/desired output Media Types and (variations on those Types)
    # are based on the input Type and the Molecule(s) available to service those Types.
    # Use an Array, since order might be important here when generating many variations
    # at multiple levels of the DistorteD stack, e.g. the actual files on the Floor level
    # and the templates/markup here in the Jekyll level.
    @changes ||= type_mars.each_with_object(Array[]) { |lower, wanted|
      # Query our configuration for Type changes, e.g. image/webp to (image/png and image/webp).
      # Handle empty sub-types by compacting and splatting a sub-Array.
      change_config = the_setting_sun(:changes, *(lower.settings_paths))
      # If there is no config, treat it as a change to the same Type as the input,
      # otherwise instantiate each "mediatype/subtype" config `String` to a `::CHECKING::YOU::OUT`.
      ((change_config.nil? || change_config&.empty?) ? Set[lower] : change_config.map { |t|
        ::CHECKING::YOU::OUT::from_iana_media_type(t)
      }).each { |type|
        # Query our configuration again for variations on each Type.
        # For example, one single image Type may want multiple resolutions to enable responsive <picture> tags,
        # or a single video Type may want multiple bitrates for adaptive streaming.
        limit_breaks = the_setting_sun(:outer_limits, *(type&.settings_paths)) || Array[Hash[]]
        # Which MediaMolecule Modules support this Type as an output? Probably just one.
        outer_limits.keep_if { |k, v| v.has_key?(type) }.keys.each { |molecule|
          # As before, if there is nothing in the config just treat it as a Change to
          # the full resolution/bitrate/whatever as the input, so this will always run at least once.
          limit_breaks.each { |limit_break|
            # Merge each variation's config with any/all attributes given to our Liquid Tag,
            # as well as any Jekyll Stuff™ like the relative destination path.
            change_arguments = limit_break.merge(Hash[:dir => @relative_dest]).merge(context_arguments)
            # Each Change will carry instance Compound data in Atom Structs so we can avoid modifying
            # the Compound Struct with any variation-specific values since they will be reused.
            atoms = Hash.new
            # We will always want an Atom from every Compound even if it only carries the :default.
            Cooltrainer::DistorteD::IMPLANTATION(:OUTER_LIMITS, molecule)&.dig(type)&.each_pair { |aka, compound|
              next if aka.nil? or compound.nil?  # Support Molecules that define Types with nil options
              next if aka != compound.element  # Skip alias Compounds since they will all be handled at once.
              # Look for a user-given argument matching any supported alias of a Compound,
              # and check those values against the Compound for validity.
              atoms.store(compound.element, Cooltrainer::Atom.new(compound.isotopes.reduce(nil) { |value, isotope|
                # TODO: valid?
                value || change_arguments&.delete(isotope)
              }, compound.default))
            }
            # After looping through the Compounds and calling :delete for matched values,
            # this bag will be left with only the freeform non-Compound-associated arguments, if any.
            # Separate those into arguments that match Change member names, and arguments that don't.
            change_member_keys, atom_keys = change_arguments.keys.partition(&Cooltrainer::Change.members.method(:include?))
            # Instantiate a no-default Atom for every remaining argument that isn't a Change member.
            atom_keys.each { |attribute| atoms.store(attribute, Cooltrainer::Atom.new(change_arguments.delete(attribute), nil)) }
            # Instantiate each variation of each Type into a Change struct
            # that will handle some of the details like output-filename generation.
            wanted.append(Cooltrainer::Change.new(type, src: @name, molecule: molecule, **change_arguments, **atoms))
          }
        }
      }
      wanted
    }
  end

  # Return any arguments given by the user to our Liquid tag.
  # This method name is generic across all DD entrypoints so it can be
  # referenced from lower layers in the pile.
  def context_arguments
    @tag_arguments ||= Hash[]
  end

  # Returns a context-only setting from our Liquid attributes.
  def abstract(key)
    context_arguments.dig(key)
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
    unless @relative_dest[-1] == Jekyll::DistorteD::PATH_SEPARATOR
      @relative_dest = File.dirname(@relative_dest)
      # Append the trailing slash so we don't have to do it
      # in the Liquid templates.
      @relative_dest << Jekyll::DistorteD::PATH_SEPARATOR
    end

    # Add our new file to the list that will be handled
    # by Jekyll's built-in StaticFile generator.
    @site.static_files << self
    render_to_output_buffer(context, '')
  end

  # A future Liquid version (5.0?) will call this function directly
  # instead of calling render()
  def render_to_output_buffer(context, output)
    roots_of_my_way = Cooltrainer::ElementalCreation.new(:root).tap { |wrapper|
      wrapper.dan = "distorted #{changes.reduce(Set[]) { |classes, change|
        classes.add(change.molecule&.name.split('::'.freeze).last.downcase)
        classes.add(change.type.genus.to_s.split(::CHECKING::YOU::OUT::type_separators)[0])
      }.to_a.join(' ')}"
    }

    changes&.each { |change|
      unless self.respond_to_missing?(change.type.distorted_template_method)
        Jekyll.logger.error(@name, "Missing template method #{change.type.distorted_template_method}")
        raise MediaTypeOutputNotImplementedError.new(@name, type_mars, self.class.name)
      end
      Jekyll.logger.debug("DistorteD::#{change.type.distorted_template_method}", File.join(change.dir, change.name))

      # Get ElementalCreation Structs from the MediaMolecule's render method.
      # WISHLIST: Remove the empty final positional Hash argument once we require a Ruby version
      # that will not perform the implicit Change-to-Hash conversion due to Change's
      # implementation of :to_hash. Ruby 2.7 will complain but still do the conversion,
      # breaking downstream callers that want a Struct they can call arbitrary key methods on.
      # https://www.ruby-lang.org/en/news/2019/12/12/separation-of-positional-and-keyword-arguments-in-ruby-3-0/
      self.send(change.type.distorted_template_method, change, **{}).yield_self { |element|
        # Support taking a single Element as well as an Array[Element],
        # by treating everything as an Array[Element].
        element.is_a?(Cooltrainer::ElementalCreation) ? Array[element] : element
      }.each { |element| roots_of_my_way.children.append(element) }
    }

    output << roots_of_my_way.render
  end

end
