
# Our custom Exceptions
require 'distorted/error_code'

# File Typer
require 'distorted/checking_you_out'
using ::DistorteD::CHECKING::YOU::OUT
require 'distorted/media_molecule'

# Set.to_hash
require 'distorted/monkey_business/set'
require 'set'

Cooltrainer::DistorteD::GEM_ROOT = File.expand_path(File.join(__dir__, '..'.freeze, '..'.freeze))

module Cooltrainer::DistorteD::Invoker
  # Returns a Hash[CHECKING::YOU::OUT] => Hash[MediaMolecule] => Hash[param_alias] => Compound
  def lower_world
    Cooltrainer::DistorteD::IMPLANTATION(:LOWER_WORLD).each_with_object(
      Hash.new { |pile, type| pile[type] = Hash[] }
    ) { |(key, types), pile|
      types.each { |type, elements| pile.update(type => {key.molecule => elements}) { |k,o,n| o.merge(n) }}
    }
  end

  # Returns a Hash[MediaMolecule] => Hash[CHECKING::YOU::OUT] => Hash[param_alias] => Compound
  def outer_limits(all: false)
    Cooltrainer::DistorteD::IMPLANTATION(
      :OUTER_LIMITS,
      (all || type_mars.empty?) ? Cooltrainer::DistorteD::media_molecules : type_mars.each_with_object(Set[]) { |type, molecules|
        molecules.merge(lower_world[type].keys)
      },
    ).each_with_object(Hash.new { |pile, type| pile[type] = Hash[] }) { |(key, types), pile|
      types.each { |type, elements| pile.update(key.molecule => {type => elements}) { |k,o,n| o.merge(n) }}
    }
  end

  # Filename without the dot-and-extension.
  def basename
    File.basename(@name, '.*')
  end

  # Returns a `::Set` of `::CHECKING::YOU::OUT` objects common to the source file and our supported MediaMolecules.
  # Each of these Molecules will be plugged to the current instance.
  def type_mars
    # TODO: Get rid of the redundant `Set[…].flatten` here once I stabilize CYO API.
    @type_mars ||= Set[::CHECKING::YOU::OUT(path)].flatten & lower_world.keys.to_set
    raise MediaTypeNotImplementedError.new(@name) if @type_mars.empty?
    @type_mars
  end

  # MediaMolecule file-type plugger.
  # Any call to a ::CHECKING::YOU::OUT's distorted_method will end up here unless
  # the Molecule that defines it has been `prepend`ed to our instance.
  def method_missing(meth, *args, **kwargs, &block)
    # Only consider method names with our prefixes.
    if ::CHECKING::YOU::OUT::distorted_method_prefixes.values.map(&:to_s).include?(meth.to_s.split(::CHECKING::YOU::OUT::type_separators)[0])
      # TODO: Might need to handle cases here where the Set[Molecule]
      # exists but none of them defined our method.
      unless self.singleton_class.instance_variable_get(:@media_molecules)
        unless outer_limits.empty?
          self.singleton_class.instance_variable_set(
            :@media_molecules,
            outer_limits.keys.each_with_object(Set[]) { |molecule, molecules|
              self.singleton_class.prepend(molecule)
              molecules.add(molecule)
            }
          )
          # `return` to ensure we don't fall through to #method_missing:super
          # if we are going to do any work, otherwise a NoMethodError will
          # still be raised despite the distorted_method :sends suceeding.
          #
          # Use :__send__ in case a Molecule defines a `:send` method.
          # https://ruby-doc.org/core/Object.html#method-i-send
          return self.send(meth, *args, **kwargs, &block)
        end
      end
    end
    # …and I still haven't found it! — What I'm looking for, that is.
    # https://www.youtube.com/watch?v=xqse3vYcnaU
    super
  end

  # Make sure :respond_to? works for yet-unplugged distorted_methods.
  # http://blog.marc-andre.ca/2010/11/15/methodmissing-politely/
  def respond_to_missing?(meth, *a)
    # We can tell if a method looks like one of ours if it has at least 3 (maybe more!)
    # underscore-separated components with a valid prefix as the first component
    # and the media-type and sub-type as the rest, e.g.
    #
    # irb(main)> 'to_application_pdf'.split('_')
    # => ["to", "application", "pdf"]
    #
    # irb(main)> ::CHECKING::YOU::OUT('.docx').first.distorted_file_method.to_s.split('_')
    # => ["write", "application", "vnd", "openxmlformats", "officedocument", "wordprocessingml", "document"]
    parts = meth.to_s.split(::CHECKING::YOU::OUT::type_separators)
    ::CHECKING::YOU::OUT::distorted_method_prefixes.values.map(&:to_s).include?(parts[0]) && parts.length > 2 || super(meth, *a)
  end

end
