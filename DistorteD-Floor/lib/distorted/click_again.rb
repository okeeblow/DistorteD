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

  # Partitions the raw `argv` into two buckets — outer_limits (String relative filenames or "media/type" Strings) and switches/arguments.
  #
  # References:
  # - glibc Program Argument Syntax Conventions https://www.gnu.org/software/libc/manual/html_node/Argument-Syntax.html
  # - POSIX Utility Argument Syntax https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap12.html#tag_12_01
  # - Windows Command-line syntax key https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/command-line-syntax-key
  #
  # The filenames will be used as the source file (first member) and destination file(s) (any others).
  # The switches/arguments will be passed to our global OptionParser's `:parse_in_order`
  # which will return the unused remainder.
  #
  # I think it should be possible to achieve this same effect with our global OptionParser alone
  # by specifying two required NoArgument Switches (source and first destination filename),
  # specifying multiple optional NoArgument Switches (additional destinations),
  # and parsing the unmodified `:argv` in permutation mode.
  # I can't figure out how to wrangle OptionParser into doing that rn tho so welp here we are.
  #
  # There is a built-in Enumeraable#partition, but:
  # - It doesn't take an accumulator variable natively.
  # - I'm bad at chaining Enumerators and idk how to chain in a `:with_object` without returning only that object.
  # - `:with_object` treats scalar types as immutable which precludes cleanly passing a boolean flag variable between iterations.
  def partition_argv(argv)
    switches, @get_out = argv.each_with_object(
      # Accumulate to a three-key Hash containing the two wanted buckets and the flag that will be discarded.
      Hash[:switches => Array.new, :get_out => Array.new, :want_value => false]
    ) { |arg, partition|
      # Switches and their values will be:
      # - Any argument beginning with a single dash, e.g. long switches like '--crop' or short switches like '-Q90'.
      # - Any non-dash argument if :want_value is flagged, e.g. the 'attention' value for the '--crop' switch.
      # Filenames will be:
      # - Anything else :)
      if partition.fetch(:want_value) and not arg[0] == '-'.freeze
        # `ARGV` Strings are frozen, so we have to replace instead of directly concat
        partition[:switches].push(partition[:switches].pop.yield_self { |last| "#{last}#{'='.freeze unless arg[0] == '='.freeze}#{arg}" })
      else
        partition[(arg[0] == '-'.freeze or partition.fetch(:want_value)) ? :switches : :get_out].push(arg)
      end
      # The *next* argument should be a value for this iteration's argument iff:
      # - This iteration is a long switch with no included value,  e.g. '--crop' but not '--crop=attention'.
      # - This iteration is a short switch with no included value, e.g. '-Q' but not '-Q90' or '-Q=90'.
      partition.store(:want_value, [
        arg[0] == '-'.freeze,                           # e.g. '--crop' or '-Q'
        !arg.include?('='.freeze),                      # e.g. not '--crop=attention' or '-Q=90'
        [
          arg[1] == '-'.freeze,                         # e.g. '--crop'
          [arg[1] == '-'.freeze, arg.length > 2].none?  # e.g. not '-Q90'
        ].any?
      ].all?)
    }.values.select(&Array.method(:===))  # Return only the Array members of the Hash
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
