
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
    @@outer_limits ||= (all ? media_molecules : type_mars.reduce(Set[]) { |molecules, type|
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
  end

  # Filename without the dot-and-extension.
  def basename
    File.basename(@name, '.*')
  end

  # Returns a Set of MIME::Types common to the source file and our supported MediaMolecules.
  # Each of these Molecules will be plugged to the current instance.
  def type_mars
    @type_mars ||= CHECKING::YOU::OUT(@name) & lower_world.keys.to_set
    raise MediaTypeNotImplementedError.new(@name) if @type_mars.empty?
    @type_mars
  end

  # MediaMolecule file-type plugger.
  # Any call to a MIME::Type's distorted_method will end up here unless
  # the Molecule that defines it has been `prepend`ed to our instance.
  def method_missing(meth, *args, **kwargs, &block)
    # Only consider method names with our prefix.
    if meth.to_s.start_with?('to_'.freeze)
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
          # https://eregon.me/blog/2019/11/10/the-delegation-challenge-of-ruby27.html
          return kwargs.empty? ? self.send(meth, *args, &block) : self.send(meth, *args, **kwargs, &block)
        end
      end
    end
    # …and I still haven't found it! — What I'm looking for, that is.
    # https://www.youtube.com/watch?v=xqse3vYcnaU
    super
  end

  # Make sure :respond_to? works for yet-unplugged distorted_methods.
  # http://blog.marc-andre.ca/2010/11/15/methodmissing-politely/
  def respond_to_missing?(meth, *)
    meth.to_s.start_with?('to_'.freeze) || super
  end

end
