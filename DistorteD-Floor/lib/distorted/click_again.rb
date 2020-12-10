require 'set'
require 'distorted/monkey_business/set'

require 'optparse'
require 'shellwords'  # Necessary for inclusion in OptionParser coercions list.

require 'distorted/invoker'
require 'distorted/checking_you_out'


module Cooltrainer; end
module Cooltrainer::DistorteD; end

# Ruby OptionParser ↹ DistorteD stuff
module Cooltrainer::DistorteD::ClickAgain

  # Custom Hash subclass for OptionParser to parse options into.
  # The custom :[]= method handles situations where OptionParser
  # is given an argument flag but not a value for that flag.
  # Using just a regular Hash with the &default_proc seen here
  # gives a Set[nil] in that case, which we don't want.
  class DistorteDOptions < Hash
    def self.new
      # Don't use hash#[]= here, because it will use the one we are redefining
      # and will create an infine loop of trying to set and access its default.
      super {|hash, key| hash.store(key, Set[])}
    end
    def []=(key, value)
      # Remember: a Set{nil} is not `:empty?`!!
      self[key] << value unless value.nil?
      # Return either the full Set after adding a value,
      # or trigger the default_proc to store an empty Set for this key.
      # This is necessary to identify options that take a value
      # but were not given with one, e.g. `-o` with no value to list output types.
      self[key]
    end
  end


  # This is defined in writing in a comment in optparse.rb's RDoc,
  # but I can't seem to find anywhere it's available directly in code,
  # so I am going to build my own.
  # Maybe I am missing something obvious, in which case I should use that
  # and get rid of this :)
  # Based on https://ruby-doc.org/stdlib/libdoc/optparse/rdoc/OptionParser.html#class-OptionParser-label-Type+Coercion
  COERCIONS = [
    Date,
    DateTime,
    Time,
    URI,
    Shellwords,
    String,
    Integer,
    Float,
    Numeric,
    TrueClass,
    FalseClass,
    Array,
    Regexp,
  ].concat(OptionParser::Acceptables::constants)

  # Generate an OptionParser for a flat Enumerable of Compounds
  COMPOUND_OPTIONPARSER = Proc.new { |compounds, from, to|
    OptionParser.new(banner = "#{from.to_s} ⟹   #{to.to_s}:") { |subopt|
      compounds.map { |compound|
        next if compound.nil?
        parts = Array[
          *compound.to_options,
        ]
        if compound.default == true
          parts.append(TrueClass)
        elsif compound.default == false
          parts.append(FalseClass)
        elsif compound.valid.is_a?(Range)
          # TODO: decide how to handle Ranges that might be hundreds/thousands of items in length.
        elsif compound.valid.is_a?(Enumerable)
          parts.append(compound.valid.to_a)
        elsif COERCIONS.include?(compound.valid.class)
          parts.append(compound.valid)
        end
        parts.append(compound.blurb)
        subopt.on(*parts)
      }
      subopt.on_tail('-h', '--help', 'Show this message')
    }
  }

  # Generate a Hash[MIME::Type] => Hash[MediaMolecule] => OptionParser
  # for file-specific input options.
  def lower_subcommands
    type_mars.reduce(Hash[]) { |commands, type|
      lower_world[type].each_pair { |molecule, aka|
        commands.update(type => {
          molecule => COMPOUND_OPTIONPARSER.call(aka.values.to_set, type, molecule)
        }) { |k,o,n| o.merge(n) }
      }
      commands
    }
  end

  # Generate a Hash[MediaMolecule] => Hash[MIME::Type] => OptionParser
  # for file-specific output options.
  def outer_subcommands(all: false)
    outer_limits(all: all).reduce(Hash[]) { |commands, (molecule, types)|
      types.each_pair { |type, aka|
        commands.update(molecule => {
          type => COMPOUND_OPTIONPARSER.call(aka.values.to_set, molecule, type)
        }) { |k,o,n| o.merge(n) }
      }
      commands
    }
  end


end
