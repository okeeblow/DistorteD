require 'set'


module Cooltrainer


  BOOLEAN_VALUES = Set[0, 1, false, true, '0'.freeze, '1'.freeze, 'false'.freeze, 'true'.freeze]


  Compound = Struct.new(:element, :valid, :default, keyword_init: true) do
    attr_reader :element, :valid, :default

    def initialize(key_or_keys, valid: Set[], default: nil)
      if key_or_keys.is_a?(Enumerable)
        @element = key_or_keys.first
        @isotopes = key_or_keys.to_set
      else
        @element = key_or_keys
        @isotopes = Set[key_or_keys]
      end
      @valid = valid
      @default = default
      p @element
      super(element: element, valid: valid, default: default)
    end

    def to_s
      "#{@element}#{" a.k.a. #{@isotopes}" if @isotopes.length > 1}: #{@valid} (#{@default})"
    end

  end  # Compound

end
