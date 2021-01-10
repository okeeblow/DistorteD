
# Our custom Exceptions
require 'distorted/error_code'

# MIME::Typer
require 'distorted/checking_you_out'

# Set.to_hash
require 'distorted/monkey_business/set'
require 'set'


module Cooltrainer; end
module Cooltrainer::DistorteD; end
module Cooltrainer::DistorteD::Invoker

  # Discover DistorteD MediaMolecules bundled with this Gem
  # TODO: and any installed as separate Gems.
  @@loaded_molecules rescue begin
    Dir[File.join(__dir__, 'molecule', '*.rb')].each { |molecule| require molecule }
    @@loaded_molecules = true
  end

  # Returns a Set[Module] of our discovered MediaMolecules.
  def media_molecules
    Cooltrainer::DistorteD::Molecule.constants.map{ |molecule|
      Cooltrainer::DistorteD::Molecule::const_get(molecule)
    }.to_set
  end

  # Returns a Hash[MIME::Type] => Hash[MediaMolecule] => Hash[param_alias] => Compound
  def lower_world
    @@lower_world ||= media_molecules.reduce(
      Hash.new{|types, type| types[type] = Hash[]}
    ) { |types, molecule|
      Set[molecule].merge(molecule.ancestors).each{ |mod|
        if mod.const_defined?(:LOWER_WORLD)
          mod.const_get(:LOWER_WORLD).each { |t, elements|
            types.update(t => {molecule => elements}) { |k,o,n| o.merge(n) }
          }
        end
      }
      types
    }
  end

  # Returns a Hash[MediaMolecule] => Hash[MIME::Type] => Hash[param_alias] => Compound
  def outer_limits(all: false)
    # Use the singleton_class instance to avoid pinning a incomplete list to the shared class.
    if self.singleton_class.instance_variable_defined?(:@outer_limits)
      return self.singleton_class.instance_variable_get(:@outer_limits)
    end
    # Build OUTER_LIMITS of every MediaMolecule if all==true or if there is
    # no currently-loaded source media file (if `type_mars` is empty),
    # otherwise just of MediaMolecules relevant to the current instance.
    self.singleton_class.instance_variable_set(:@outer_limits,
       ((all || type_mars.empty?) ? media_molecules : type_mars.reduce(Set[]) { |molecules, type|
        molecules.merge(lower_world[type].keys)
      }).reduce(
        Hash.new{|molecules, molecule| molecules[molecule] = Hash[]}
      ) { |molecules, molecule|
        Set[molecule].merge(molecule.ancestors).each{ |mod|
          if mod.const_defined?(:OUTER_LIMITS)
            mod.const_get(:OUTER_LIMITS).each { |t, elements|
              molecules.update(molecule => {t => elements}) { |k,o,n| o.merge(n) }
            }
          end
        }
        molecules
      }
    )
  end

  # Filename without the dot-and-extension.
  def basename
    File.basename(@name, '.*')
  end

  # Returns a Set of MIME::Types common to the source file and our supported MediaMolecules.
  # Each of these Molecules will be plugged to the current instance.
  def type_mars
    @type_mars ||= CHECKING::YOU::OUT(path, so_deep: true) & lower_world.keys.to_set
    raise MediaTypeNotImplementedError.new(@name) if @type_mars.empty?
    @type_mars
  end

  # MediaMolecule file-type plugger.
  # Any call to a MIME::Type's distorted_method will end up here unless
  # the Molecule that defines it has been `prepend`ed to our instance.
  def method_missing(meth, *args, **kwargs, &block)
    # Only consider method names with our prefixes.
    if MIME::Type::DISTORTED_METHOD_PREFIXES.values.map(&:to_s).include?(meth.to_s.split(MIME::Type::SUB_TYPE_SEPARATORS)[0])
      # TODO: Might need to handle cases here where the Set[Molecule]
      # exists but none of them defined our method.
      unless self.singleton_class.instance_variable_get(:@media_molecules)
        unless outer_limits.empty?
          self.singleton_class.instance_variable_set(
            :@media_molecules,
            outer_limits.keys.reduce(Set[]) { |molecules, molecule|
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
    # irb(main)> CHECKING::YOU::OUT('.docx').first.distorted_file_method.to_s.split('_')
    # => ["write", "application", "vnd", "openxmlformats", "officedocument", "wordprocessingml", "document"]
    parts = meth.to_s.split(MIME::Type::SUB_TYPE_SEPARATORS)
    MIME::Type::DISTORTED_METHOD_PREFIXES.values.map(&:to_s).include?(parts[0]) && parts.length > 2 || super(meth, *a)
  end

end
