
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

  @@loaded_molecules rescue begin
    Dir[File.join(__dir__, 'molecule', '*.rb')].each { |molecule| require molecule }
    @@loaded_molecules = true
  end

  # Enabled media_type drivers. These will be attempted back to front.
  def media_molecules
    Cooltrainer::DistorteD::Molecule.constants.map{ |molecule|
      Cooltrainer::DistorteD::Molecule::const_get(molecule)
    }.to_set
  end

  def lower_world
    @@lower_world ||= media_molecules.reduce(
      Hash.new{|molecules, molecule| molecules[molecule] = Hash[]}
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

  def outer_limits
    @@outer_limits ||= media_molecules.reduce(
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

  # Decides which MediaMolecule is most appropriate for our file and returns it.
  def media_molecule
    available_molecules = lower_world.keys.to_set & type_mars
    # TODO: Handle multiple molecules for the same file
    case available_molecules.length
    when 0
      raise MediaTypeNotImplementedError.new(@name)
    when 1
      return plug(lower_world[available_molecules.first].keys.first)
    end
  end

  def plug(media_molecule)
    unless self.singleton_class.instance_variable_defined?(:@media_molecule)
      self.singleton_class.instance_variable_set(:@media_molecule, media_molecule)
      self.singleton_class.prepend(media_molecule)
    end
    media_molecule
  end

  def type_mars
    @type_mars ||= CHECKING::YOU::OUT(@name)
  end

end
