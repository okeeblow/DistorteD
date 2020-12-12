
require 'set'
require 'distorted/monkey_business/set'

require 'distorted/invoker'
require 'distorted/click_again'
require 'distorted/checking_you_out'


module Cooltrainer; end
module Cooltrainer::DistorteD; end

# DistorteD CLI
class Cooltrainer::DistorteD::Floor

  include Cooltrainer::DistorteD::Invoker  # MediaMolecule plugger
  include Cooltrainer::DistorteD::ClickAgain  # DistorteD ↹ OptionParser stuff

  attr_reader :global_options, :lower_options, :outer_options


  # Set up and parse a given Array of command-line switches based on
  # our global OptionParser and its Type/Molecule-specific sub-commands.
  #
  # :argv will be operated on destructively!
  # Consider passing a duplicate of ARGV instead of passing it directly.
  def initialize(argv, exe_name)

    # Initialize Hashes to store our three types of Options using a small
    # custom subclass that will store items as a Set but won't store :nil alone.
    @global_options = DistorteDOptions.new
    @lower_options = Hash.new { |opts,type|
      opts[type] = Hash.new { |type, molecule|
        type[molecule] = DistorteDOptions.new
      }
    }
    @outer_options = Hash.new { |opts,molecule|
      opts[molecule] = Hash.new { |molecule, type|
        molecule[type] = DistorteDOptions.new
      }
    }

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
      global.permute!(argv, into: @global_options)
    rescue OptionParser::InvalidOption => nope
      argv = nope.recover(argv)
      exit
    end

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
    @name = argv.shift

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
    when argv.empty? && @global_options.keys.empty?
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
    lower_subcommands.each_pair { |type, molecule|
      molecule.each_value { |subcommand|
        begin
          subcommand.order!(into: @lower_options[type][molecule])
        rescue OptionParser::InvalidOption => nope
          argv = nope.recover(argv)
          raise
        end
      }
    }
    outer_subcommands.each_pair { |molecule, type|
      type.each_value { |subcommand|
        begin
          subcommand.order!(into: @outer_options[molecule][type])
        rescue OptionParser::InvalidOption => nope
          argv = nope.recover(argv)
          raise
        end
      }
    }

    # Anything left over should be the list of our output filenames
    @argv = argv
  end

  # Writes all intended output files to a given directory.
  def write(dest_root)
    changes.each_pair { |type, change|
      molecule = lower_world[type]
      change.each { |c|
        filename = File.expand_path(c.name, dest_root)

        if self.respond_to?(type.distorted_method)
          self.send(type.distorted_method, filename, **c)
        elsif type_mars.include?(type)
          #copy_file(filename)
        else
          raise MediaTypeOutputNotImplementedError.new(filename, type, self.class.name)
        end
      }
    }
  end

  private

  # Generic top-level OptionParser
  def global_options(exe_name)
    OptionParser.new do |opts|
      opts.banner = "Usage: #{exe_name} [OPTION]… SOURCE DEST [DEST]…"
      opts.on_tail('-h', '--help', 'Show this message')
      opts.on('-v', '--[no-]verbose', 'Run verbosely')
      opts.on('-l [LOWER WORLD]', '--lower-world [LOWER WORLD]', 'Show supported input media types')
      opts.on('-o [OUTER LIMITS]', '--outer-limits [OUTER LIMITS]', 'Show supported output media types')
    end
  end

  # Returns a Hash[MIME::Type] => Change for every intended output variation.
  def changes
    vers = Set[:full]
    explicit_outer = @global_options&.dig(:"outer-limits") || []
    (explicit_outer.length == @argv.length ?
      @argv.zip(explicit_outer.map{|a| CHECKING::YOU::OUT[a]}) :
      @argv.zip(@argv.map{ |a| CHECKING::YOU::OUT(a).first})
    ).reduce(Hash[]){ |wanted, (f,t)|
      # TODO: Nice way to check format for Type string here.
      # Should be e.g. "image/png"
      wanted.store(t, vers.map{ |v|
        Cooltrainer::Change.new(t, tag: v, name: f)
      })
      wanted
    }
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

end
