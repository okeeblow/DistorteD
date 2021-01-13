require 'optparse'
require 'date'

module Cooltrainer

  # This is defined in writing in a comment in optparse.rb's RDoc,
  # but I can't seem to find anywhere it's available directly in code,
  # so I am going to build my own.
  # Maybe I am missing something obvious, in which case I should use that
  # and get rid of this :)
  # Based on https://ruby-doc.org/stdlib/libdoc/optparse/rdoc/OptionParser.html#class-OptionParser-label-Type+Coercion
  OPTIONPARSER_COERSIONS = [
    Date,
    DateTime,
    Time,
    URI,
    #Shellwords,  # Stock in optparse, but under autoload. I don't want it.
    String,
    Integer,
    Float,
    Numeric,
    TrueClass,
    FalseClass,
    Array,
    Regexp,
  ].concat(OptionParser::Acceptables::constants)


  # Struct to wrap a MediaMolecule option/attribute datum.
  Compound = Struct.new(:isotopes, :molecule, :valid, :default, :blurb, keyword_init: true) do

    # Massage the data then call `super` to set the members/values and create the accessors.
    def initialize(isotopes, molecule: nil, valid: nil, default: nil, blurb: nil)
      super(
        # The first argument defines the aliases for a single option and may be just a Symbol
        # or may be an Enumerable[Symbol] in which case all items after the first are aliases for the first.
        isotopes: isotopes.is_a?(Enumerable) ? isotopes.to_a : Array[isotopes],
        # Hint the MediaMolecule that should execute this Change.
        molecule: molecule,
        # Valid values for this option may be expressed as a Class a value must be an instance of,
        # a Regexp a String value must match, an Enumerable that a valid value must be in,
        # a Range a Float/Integer must be within, a special Boolean Set, etc etc.
        valid: case valid
          when Set then valid.to_a
          else valid
        end,
        # Optional default value to use when unset.
        default: default,
        # String description of this option's effect.
        blurb: blurb,
      )
    end

    # The first isotope is the """real""" option name. Any others are aliases for it.
    def element; self.isotopes&.first; end
    def to_s; self.element.to_s; end

    # Returns a longform String representation of one option.
    def inspect
      # Intentionally not including the blurb here since they are pretty long and messy.
      "#{self.isotopes.length > 1 ? self.isotopes : self.element}: #{"#{self.valid} " if self.valid}#{"(#{self.default})" if self.default}"
    end

    # Returns an Array of properly-formatted OptionParser::Switch strings for this Compound.
    def to_options
      # @isotopes is a Hash[Symbol] => Compound, allowing for Compound aliasing
      # to multiple Hash keys, e.g. libvips' `:Q` and `:quality` are two Hash keys
      # referencing the same Compound object.
      self.isotopes.each_with_object(Array[]) { |aka, commands|
        # Every Switch has at least one leading dash, and longer ones have two,
        # e.g. `-Q` vs `--quality`.
        command = "-"
        if aka.length > 1
          command << '-'.freeze
        end

        # Compounds that take a boolean should format their Switch string
        # as `--[no]-whatever` (including the brackets!) instead of taking
        # any kind of boolean-ish argument like true/false/yes/no.
        #
        # TODO: There seems to be a bug with Ruby optparse and multiple of these
        # "--[no]-whatever"-style Switches where only the final Switch will display,
        # so disable this for now in favor of separate --whatever/--no-whatever.
        # I have a very basic standalone repro case that fails, so it's not just DD.
        #
        #if @valid == BOOLEAN_VALUES or @valid == BOOLEAN_VALUES.to_a
        #  command << '[no]-'.freeze
        #end

        # Add the alias to form the command.
        command << aka.to_s

        # Format the valid values and/or default value and stick it on the end.
        # https://ruby-doc.org/stdlib/libdoc/optparse/rdoc/OptionParser.html#class-OptionParser-label-Type+Coercion
        if self.valid.is_a?(Range)
          command << " [#{self.valid.to_s}]"
        elsif self.valid == BOOLEAN_VALUES or self.valid == BOOLEAN_VALUES.to_a
          # Intentional no-op
        elsif self.valid.is_a?(Enumerable)
          command << " [#{self.valid.join(', '.freeze)}]"
        elsif not default.nil?
          command << " [#{self.default}]"
        else
          command << " [#{self.element.upcase}]"
        end

        commands << command

        # HACK around issue with multiple "--[no]-whatever"-style long arguments.
        # See above note and the commented-out implementation I'd like to use
        # instead of this. Remove this iff I can figure out what's wrong there.
        if self.valid == BOOLEAN_VALUES or self.valid == BOOLEAN_VALUES.to_a
          commands << "--no-#{aka}"
        end
      }
    end  # to_options

  end  # Compound

end
