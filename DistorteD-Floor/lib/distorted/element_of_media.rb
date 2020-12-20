require 'set'

require 'distorted/checking_you_out'


module Cooltrainer


  # Fun Ruby Fact™: `false` is always object_id 0
  # https://skorks.com/2009/09/true-false-and-nil-objects-in-ruby/
  # irb(main):650:0> true.object_id
  # => 20
  # irb(main):651:0> false.object_id
  # => 0
  BOOLEAN_VALUES = Set[false, true]


  Change = Struct.new(:type, :name, :molecule, :tag, :extra, keyword_init: true) do

    attr_reader :type, :molecule, :tag, :extra

    FALLBACK_TYPE = CHECKING::YOU::OUT['application/x.distorted.never-let-you-down']

    def initialize(type, name: nil, molecule: nil, tag: :full, **extra)
      @type = type
      @tag = tag
      @molecule = molecule
      # Don't change the filename of full-size variations
      @filetag = tag == :full ? ''.freeze : '-'.concat(tag.to_s)
      # Use the original extname for LastResort
      @ext = type == FALLBACK_TYPE ? File.extname(name) : type.preferred_extension
      # Handle LastResort for files that might be a bare name with no extension
      @dot = '.'.freeze unless @ext.nil? || @ext&.empty?
      @basename = File.basename(name, '.*')
      @extra = extra
      super(type: type, name: name, molecule: molecule, tag: tag, extra: extra)

      # Define accessors for context-specific :extra keys/values that aren't normal Struct members.
      extra.each_key{ |k|
        self.singleton_class.define_method(k) {self.extra.dig(k)}
        self.singleton_class.define_method("#{k}=".to_sym) {|v| self.extra.store(k, v)}
      }
    end

    def name
      "#{@basename}#{@filetag}#{@dot}#{@ext}"
    end

    # A generic version of Struct#to_hash was rejected with good reason,
    # but I'm going to use it here because I want the implicit Struct-to-Hash
    # conversion to let me use these Structs with a double-splat.
    # https://bugs.ruby-lang.org/issues/4862
    def to_hash
      Hash[self.members.reject{|m| m == :extra}.zip(self.values.reject{|v| v.is_a?(Hash)})].merge(@extra || Hash[])
    end
    def to_h
      Hash[self.members.reject{|m| m == :extra}.zip(self.values.reject{|v| v.is_a?(Hash)})].merge(@extra || Hash[])
    end
  end


  Compound = Struct.new(:element, :valid, :default, :blurb, keyword_init: true) do
    attr_reader :element, :isotopes, :valid, :default, :blurb

    def initialize(key_or_keys, valid: nil, default: nil, blurb: nil)
      # Intentionally using Array for isotopes to guarantee order (vs Set)
      # so we can tell the "real" element from any aliases,
      # because the primary attribute name will always be the first.
      if key_or_keys.is_a?(Enumerable)
        @element = key_or_keys.first
        @isotopes = key_or_keys.to_a
      else
        @element = key_or_keys
        @isotopes = Array[key_or_keys]
      end
      @valid = case valid
      when Set then valid.to_a
      else valid
      end
      @default = default
      @blurb = blurb
      super(element: element, valid: valid, default: default, blurb: blurb)
    end

    def inspect
      # Intentionally not including the blurb here since they are pretty long and messy.
      "#{@element}#{" a.k.a. #{@isotopes}" if @isotopes.length > 1}: #{"#{@valid} " if @valid}(#{@default})"
    end

    # Returns a Set of properly-formatted OptionParser::Switch strings for this Compound.
    def to_options
      # @isotopes is a Hash[Symbol] => Compound, allowing for Compound aliasing
      # to multiple Hash keys, e.g. libvips' `:Q` and `:quality` are two Hash keys
      # referencing the same Compound object.
      @isotopes.reduce(Array[]) { |commands, aka|
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
        if @valid.is_a?(Range)
          command << " [#{@valid.to_s}]"
        elsif @valid == BOOLEAN_VALUES or @valid == BOOLEAN_VALUES.to_a
          # Intentional no-op
        elsif @valid.is_a?(Enumerable)
          command << " [#{@valid.join(', '.freeze)}]"
        elsif not @default.nil?
          command << " [#{@default}]"
        else
          command << " [#{@element.upcase}]"
        end

        commands << command

        # HACK around issue with multiple "--[no]-whatever"-style long arguments.
        # See above note and the commented-out implementation I'd like to use
        # instead of this. Remove this iff I can figure out what's wrong there.
        if @valid == BOOLEAN_VALUES or @valid == BOOLEAN_VALUES.to_a
          commands << "--no-#{aka}"
        end

        commands
      }
    end  # to_options

  end  # Compound

end
