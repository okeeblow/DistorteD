require 'set'

require 'distorted/checking_you_out'


module Cooltrainer


  BOOLEAN_VALUES = Set[0, 1, false, true, '0'.freeze, '1'.freeze, 'false'.freeze, 'true'.freeze]


  Change = Struct.new(:type, :name, :molecule, :tag, :extra, keyword_init: true) do
    attr_reader :type, :molecule, :tag, :extra

    def initialize(type, name: nil, molecule: nil, tag: :full, **extra)
      @type = type
      @tag = tag
      @molecule = molecule
      # Don't change the filename of full-size variations
      @filetag = tag == :full ? ''.freeze : '-'.concat(tag.to_s)
      # Use the original extname for LastResort
      @ext = type == CHECKING::YOU::OUT['application/x.distorted.last-resort'] ? File.extname(name) : type.preferred_extension
      # Handle LastResort for files that might be a bare name with no extension
      @dot = '.'.freeze unless @ext.nil? || @ext&.empty?
      @basename = File.basename(name, '.*')
      @extra = extra
      super(type: type, name: name, molecule: molecule, tag: tag, extra: extra)
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
      if key_or_keys.is_a?(Enumerable)
        @element = key_or_keys.first
        @isotopes = key_or_keys.to_set
      else
        @element = key_or_keys
        @isotopes = Set[key_or_keys]
      end
      @valid = valid
      @default = default
      @blurb = blurb
      super(element: element, valid: valid, default: default, blurb: blurb)
    end

    def inspect
      # Intentionally not including the blurb here since they are pretty long and messy.
      "#{@element}#{" a.k.a. #{@isotopes}" if @isotopes.length > 1}: #{"#{@valid} " if @valid}(#{@default})"
    end

    def to_options
      @isotopes.reduce(Set[]) { |commands, aka|
        command = "-#{'-'.freeze if aka.length > 1}#{aka.to_s}"
        if @valid.is_a?(Range)
          command << " [#{@valid.to_s}]"
        elsif @valid.is_a?(Enumerable)
          command << " [#{@valid.join(', '.freeze)}]"
        elsif not @default.nil?
          command << " [#{@default}]"
        else
          command << " [#{@element.upcase}]"
        end
        commands << command
      }
    end

  end  # Compound

end
