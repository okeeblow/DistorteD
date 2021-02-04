require 'set'
require 'distorted/monkey_business/set'

require 'optparse'
require 'shellwords'  # Necessary for inclusion in OptionParser coercions list.

require 'distorted/invoker'
require 'distorted/checking_you_out'
require 'distorted/element_of_media/compound'


module Cooltrainer; end
module Cooltrainer::DistorteD; end

class Cooltrainer::DistorteD::ClickAgain

  include Cooltrainer::DistorteD::Invoker  # MediaMolecule plugger

  attr_reader :global_options, :lower_options, :outer_options


  # Set up and parse a given Array of command-line switches based on
  # our global OptionParser and its Type/Molecule-specific sub-commands.
  #
  # :argv will be operated on destructively!
  # Consider passing a duplicate of ARGV instead of passing it directly.
  def initialize(argv, exe_name)

    # Partition argv into (switches and their arguments) and (filenames or wanted type Strings)
    switches, @get_out = partition_argv(argv)

    # Initialize Hashes to store our three types of Options using a small
    # custom subclass that will store items as a Set but won't store :nil alone.
    @global_options = Hash.new { |h,k| h[k] = h.class.new(&h.default_proc) }
    @lower_options = Hash.new { |h,k| h[k] = h.class.new(&h.default_proc) }
    @outer_options = Hash.new { |h,k| h[k] = h.class.new(&h.default_proc) }
    # Temporary Array for unmatched Switches when parsing subcommands.
    sorry_try_again = Array.new

    # Pass our executable name in for the global OptionParser's banner String,
    # then parse the complete/raw user-given-arguments-list first with this Parser.
    #
    # I am intentionally using OptionParser's non-POSIXy :permute! method
    # instead of the POSIX-compatible :order! method,
    # because I want to :)
    # Otherwise users would have to define all switch arguments
    # ahead of all positional arguments in the command,
    # and I think that would be frustrating and silly.
    #
    # In strictly-POSIX mode, one would have to call e.g.
    #   `distorted -o image/png inputfile.webp outfilewithnofileextension`
    # instead of
    #   `distorted inputfile.webp -o image/png outfilewithnofileextension`,
    # which I find to be much more intuitive.
    #
    # Note that `:parse!` would call one of the other of :order!/:permute! based on
    # an invironment variable `POSIXLY_CORRECT`. Talk about a footgun!
    # Be explicit!!
    global = global_options(exe_name)
    begin
      switches = global.permute!(switches, into: @global_options)
    rescue OptionParser::InvalidOption, OptionParser::MissingArgument, OptionParser::ParseError => nope
      nope.recover(sorry_try_again)  # Will :unshift the :nope value to the recovery Array.
      #if switches&.first&.chr == '-'.freeze
      #  sorry_try_again.unshift(switches.shift)
      #end
      retry
    end
    switches.unshift(*sorry_try_again.reverse)

    # The global OptionParser#permute! call will strip our `:argv` Array of
    # any `--help` or Molecule-picking switches.
    # Molecule-specific switches (both 'lower' and 'outer') and positional
    # file-name arguments remain.
    #
    # The first remaining `argv` will be our input filename if one was given!
    #
    # NOTE: Never assume this filename will be a complete, absolute, usable path.
    # POSIX shells do not do tilde expansion, for example, on quoted switch arguments,
    # so a quoted filename argument '~/cover.png' will come through to Ruby-land
    # as the literal String '~/cover.png' while the same filename argument sans-quotes
    # will be expanded to e.g. '/home/okeeblow/cover.png' (based on `$HOME` env var).
    # Additional Ruby-side path validation will almost certainly be needed!
    # https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_06_01
    @name = @get_out&.shift

    # Print some sort of help message or list of supported input/output Types
    # if no source filename was given.
    unless @name 
      puts case
      when @global_options.has_key?(:help) then global
      when @global_options.has_key?(:"lower-world")
        "Supported input media types:\n#{lower_world.keys.join("\n")}"
      when @global_options.has_key?(:"outer-limits")
        "Supported output media types:\n#{outer_limits(all: true).values.map{|m| m.keys}.join("\n")}"
      else global
      end
      exit
    end

    # Here's that additional filename validation I was talking about.
    # I don't do this as a one-shot with the argv.shift because
    # File::expand_path raises an error on :nil argument,
    # and we already checked for that when we checked for 'help' switches.
    @name = File.expand_path(@name)

    # Check for 'help' switches *again* now that we have a source file path,
    # because the output can be file-specific instead of generic.
    # This is where we display subcommands' help!
    specific_help = case
    when @get_out.empty?
      # Only input filename given; no outputs; nothing left to do!
      lower_subcommands.merge(outer_subcommands).values.unshift(Hash[:DistorteD => [global]]).map { |l|
        l.values.join("\n")
      }.join("\n")
    when @global_options.has_key?(:help), @global_options.has_key?(:"lower-world")
      lower_subcommands.values.map { |l|
        l.values.join("\n")
      }.join("\n")
    when @global_options.has_key?(:"outer-limits")
      # Trigger this help message on `-o` iff that switch is used bare.
      # If `-o` is given an argument it will inform the MIME::Type
      # of the same-index output file, e.g.
      # `-o image/png -o image/webp pngnoextension webpnoextension`
      # will work exactly as that example implies.
      @global_options.dig(:"outer-limits")&.empty? ?
      outer_subcommands.values.map { |o|
        o.values.join("\n")
      }.join("\n") : nil
    else nil
    end
    if specific_help
      puts specific_help
      exit
    end

    # Our "subcommands" are additional instances of OptionParser,
    # one for every MediaMolecule that can load the source file,
    # and one for every intended output variation.
    lower_subcommands.each_pair { |type, molecule_commands|
      molecule_commands.each_pair { |molecule, subcommand|
        begin
          switches = subcommand.permute!(switches, into: @lower_options[type][molecule])
        rescue OptionParser::InvalidOption, OptionParser::MissingArgument, OptionParser::ParseError => nope
          nope.recover(sorry_try_again)  # Will :unshift the :nope value to the recovery Array.
          retry
        end
        switches.unshift(*sorry_try_again.reverse)
        @lower_options[type][molecule].store(:molecule, molecule)
      }
    }
    outer_subcommands.each_pair { |molecule, type_commands|
      type_commands.each_pair { |type, subcommand|
        begin
          switches = subcommand.permute!(switches, into: @outer_options[molecule][type])
        rescue OptionParser::InvalidOption, OptionParser::MissingArgument, OptionParser::ParseError => nope
          nope.recover(sorry_try_again)  # Will :unshift the :nope value to the recovery Array.
          retry
        end
        switches.unshift(*sorry_try_again.reverse)
        @outer_options[molecule][type].store(:molecule, molecule)
      }
    }
  end

  # Writes all intended output files to a given directory.
  # `dest_root` is a Jekyll-ism not used here in the CLI, but define it anyway for consistency.
  def write(dest_root = nil)
    changes.each { |change|
      if self.respond_to?(change.type.distorted_file_method)
        # WISHLIST: Remove the empty final positional Hash argument once we require a Ruby version
        # that will not perform the implicit Change-to-Hash conversion due to Change's
        # implementation of :to_hash. Ruby 2.7 will complain but still do the conversion,
        # breaking downstream callers that want a Struct they can call arbitrary key methods on.
        # https://www.ruby-lang.org/en/news/2019/12/12/separation-of-positional-and-keyword-arguments-in-ruby-3-0/
        self.send(change.type.distorted_file_method, dest_root, change, **{})
      else
        raise MediaTypeOutputNotImplementedError.new(change.name, change.type, self.class.name)
      end
    }
  end

  private

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
      #
      # Combine long switches like '--crop' with their value as a single String with equals, e.g. '--crop=none'.
      # Combine short switches like '-Q' with their value as a single String without equals, e.g. '-Q90'.
      if partition.fetch(:want_value) and arg[0] != '-'.freeze  # Does this look like a value when we want a value?
        # `ARGV` Strings are frozen, so we have to replace instead of directly concat
        partition[:switches].push(partition[:switches].pop.yield_self { |last|
          # Prefix the value with equals for long switches if we don't already have one.
          "#{last}#{'='.freeze if last[1] == '-'.freeze and arg[0] != '='.freeze}#{arg}"
        })
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

  # Generic top-level OptionParser
  def global_options(exe_name)
    OptionParser.new do |opts|
      opts.banner = "Usage: #{exe_name} [OPTION]… SOURCE DEST [DEST]…"
      opts.on_tail('-h', '--help', 'Show this message')
      opts.on('-v', '--[no-]verbose', 'Run verbosely')
      opts.on('-l', '--lower-world', 'Show supported input media types')
      opts.on('-o', '--outer-limits', 'Show supported output media types')
    end
  end

  # Returns an Array[Change] for every intended output variation.
  def changes
    @changes ||= begin
      # TODO: Consume @lower_options as well, and figure out how to specify Molecule
      # for future situations where multiple Molecules may overlap.
      # Until then, just collapse @outer_options to one Hash and take anything we find for our Type.
      combined_outer_options = @outer_options.each_with_object(Array.new) { |(molecule,type_options),combined| combined.push(type_options) }.reduce(&:merge)
      @get_out.each_with_object(Array[]) { |out, wanted|
        # TODO: Nice way to check format for Type string here.
        # Should be e.g. "image/png"
        if CHECKING::YOU::OUT[out].nil?
          name = out
          type = CHECKING::YOU::OUT(out).first
        else
          name = @name
          type = CHECKING::YOU::OUT[out]
        end
        type_options = combined_outer_options.fetch(type, Hash.new)
        atoms = Hash.new
        Cooltrainer::DistorteD::IMPLANTATION(:OUTER_LIMITS, type_options[:molecule])&.dig(type)&.each_pair { |aka, compound|
          next if aka.nil? or compound.nil?  # Allow Molecules to define Types with no options.
          next if aka != compound.element  # Skip alias Compounds since they will all be handled at once.
          # Look for a user-given argument matching any supported alias of a Compound,
          # and check those values against the Compound for validity.
          atoms.store(compound.element, Cooltrainer::Atom.new(compound.isotopes.reduce(nil) { |value, isotope|
            # TODO: valid?
            value || type_options&.delete(isotope)
          }, compound.default))
        }
        wanted.push(Cooltrainer::Change.new(type, src: name, dir: Cooltrainer::Atom.new(File.dirname(name)), **atoms))
      }
    end
  end

  # Returns an absolute String path to the source file.
  def path
    File.expand_path(@name)
  end

  # This is a CLI, so we always want to write new files when called.
  def modified?
    true
  end

  # And again.
  def write?
    true
  end

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
        elsif Cooltrainer::OPTIONPARSER_COERSIONS.include?(compound.valid.class)
          parts.append(compound.valid)
        end
        parts.append(compound.default.nil? ? compound.blurb : "#{compound.blurb} (default: #{compound.default})")

        # Avoid using a `subopt.accept(Range)` Proc to handle Ranges,
        # because that would only allow us to define a single handler for all Ranges
        # regardless of the type or value they represent.
        # The value yielded from this block will be the value recieved by parse_in_order's `into`.
        if compound.valid.is_a?(Range)
          subopt.on(*parts) do |value|
            if compound.valid.to_a.all?(Integer)
              value = Integer(value)
            elsif compound.valid.to_a.all(Float)
              value = Float(value)
            end
            next compound.valid.include?(value) ? value : compound.default
          end
        else
          subopt.on(*parts)
        end
      }
    }
  }

  # Generate a Hash[MIME::Type] => Hash[MediaMolecule] => OptionParser
  # for file-specific input options.
  def lower_subcommands
    type_mars.each_with_object(Hash[]) { |type, commands|
      lower_world[type].each_pair { |molecule, aka|
        commands.update(type => {
          molecule => COMPOUND_OPTIONPARSER.call(aka&.values.to_set, type, molecule)
        }) { |k,o,n| o.merge(n) } unless aka.nil?
      }
    }
  end

  # Generate a Hash[MediaMolecule] => Hash[MIME::Type] => OptionParser
  # for file-specific output options.
  def outer_subcommands(all: false)
    outer_limits(all: all).each_with_object(Hash[]) { |(molecule, types), commands|
      types.each_pair { |type, aka|
        commands.update(molecule => {
          type => COMPOUND_OPTIONPARSER.call(aka&.values.to_set, molecule, type)
        }) { |k,o,n| o.merge(n) } unless aka.nil?
      }
    }
  end

end
