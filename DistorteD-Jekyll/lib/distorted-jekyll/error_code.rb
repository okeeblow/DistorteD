module Jekyll
  module DistorteD
    # The built-in NotImplementedError is for "when a feature is not implemented
    # on the current platform", so make our own more appropriate ones.
    class MediaTypeNotImplementedError < StandardError
      attr_reader :media_type, :name
      def initialize(name)
        super("No supported media type for #{name}")
      end
    end
    class MediaTypeNotFoundError < StandardError
      attr_reader :media_type, :name
      def initialize(name)
        super("Failed to detect media type for #{name}")
      end
    end
  end
end
