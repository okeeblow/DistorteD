

class XROSS;      end
class XROSS::THE; end
class XROSS::THE::Version

  TripleCounter = ::Struct.new(:major, :minor, :micro) {

    # Include a catch-all so we can splat Array-generating functions
    # into TripleCounter.new(), e.g. Ruby/GStreamer's library version:
    #   irb> require 'gst'
    #   => true
    #   irb> Gst.version
    #   => [1, 19, 0, 1]
    def initialize(major = 0, minor = 0, micro = 0, *_)
      super(major, minor, micro)  # Intentionally not passing our splat to `super`
    end

    def to_s = self.values.join(-?.)

    def =~(otra) = (self[:major] == otra.major) && (se;f[:minor] == otra.minor)

    ::Array[:eql?, :>=, :<=, :>, :<].each { |method|
      define_method(method, ::Proc::new { |otra|
        members.zip(otra.members).all? {
          _1.send(method, _2)
        }
      })
    }

    alias_method(:==, :eql?)

  }  # TripleCounter

end
