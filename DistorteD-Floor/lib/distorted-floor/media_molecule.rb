require 'set'

module Cooltrainer; end
module Cooltrainer::DistorteD

  # Discover DistorteD MediaMolecules bundled with this Gem
  # TODO: and any installed as separate Gems.
  @@loaded_molecules rescue begin
    Dir[File.join(__dir__, 'molecule', '*.rb')].each { |molecule| require molecule }
    @@loaded_molecules = true
  end

  # Returns a Set[Module] of our discovered MediaMolecules.
  def self.media_molecules
    Cooltrainer::DistorteD::Molecule.constants.map { |molecule|
      Cooltrainer::DistorteD::Molecule::const_get(molecule)
    }.to_set
  end

  # Reusable IMPLANTATION Hash key, since instances of the same Struct subclass are equal:
  # irb> Pair = Struct.new(:uno, :dos)
  # irb> lol = Pair.new(:a, 1)
  # irb> rofl = Pair.new(:a, 1)
  # irb> lol === rofl
  # => true
  KEY = Struct.new(:molecule, :constant, :inherit) do
    # Descend into ancestor Modules by default.
    def initialize(molecule, constant, inherit = true); super(molecule, constant, inherit); end
    def inspect; "#{molecule}#{'∫'.freeze if inherit}::#{constant}"; end
  end

  # Check and create attribute-memoizing Hash whose default_proc will fetch
  # and collate the data for a given KEY.
  @@implantation rescue begin
    @@implantation = Hash.new { |piles, key| 
      # Optionally limit search to top-level Module like `:const_defined?` with `inherit`
      piles[key] = Set[key.molecule].merge(key.inherit ? key.molecule.ancestors : []).each_with_object(Hash.new) { |mod, pile|
        mod.const_get(key.constant).each { |target, elements|
          pile.update(target => elements) { |_key, existing, new| existing.merge(new) }
        } rescue nil 
      }
    }
  end

  # Generic entry-point for attribute-collation of a given constant
  # over a given Molecule or Enumerable of Molecules.
  def self.IMPLANTATION(constant, corpus = self.media_molecules)
    (corpus.is_a?(Enumerable) ? corpus : Array[corpus]).map { |molecule|
      KEY.new(molecule, constant)
    }.each_with_object(Hash[]) { |key, piles|
      # Hash#slice doesn't trigger the default_proc, so access each directly.
      piles.store(key, @@implantation[key])
    }.yield_self { |piles|
      # Return just the data when we were given a single Molecule to search.
      corpus.is_a?(Enumerable) ? piles : piles.shift[1]
    }
  end
end
