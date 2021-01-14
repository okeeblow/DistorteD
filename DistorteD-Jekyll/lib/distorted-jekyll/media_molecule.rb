require 'set'
require 'distorted/media_molecule'

module Jekyll::DistorteD
  # Load Jekyll Molecules which will implicitly also load
  # the Floor Molecules they're based on if they aren't already.
  @@loaded_molecules rescue begin
    Dir[File.join(__dir__, 'media_molecule', '*.rb')].each { |molecule| require molecule }
    @@loaded_molecules = true
  end
end

module Cooltrainer::DistorteD
  # Override default Molecule Set with their Liquid-rendering submolecules.
  def self.media_molecules
    Jekyll::DistorteD::Molecule.constants.map { |molecule|
      Jekyll::DistorteD::Molecule::const_get(molecule)
    }.to_set
  end
end
