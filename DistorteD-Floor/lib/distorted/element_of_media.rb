require 'set'


module Cooltrainer


  BOOLEAN_VALUES = Set[0, 1, false, true, '0'.freeze, '1'.freeze, 'false'.freeze, 'true'.freeze]


  Compound = Struct.new(:element, :valid, :default, :blurb, keyword_init: true) do
    attr_reader :element, :valid, :default, :blurb

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
      super(element: element, valid: valid, default: default, blurb: blurb)
    end

    def inspect
      # Intentionally not including the blurb here since they are pretty long and messy.
      "#{@element}#{" a.k.a. #{@isotopes}" if @isotopes.length > 1}: #{"#{@valid} " if @valid}(#{@default})"
    end

  end  # Compound

end
