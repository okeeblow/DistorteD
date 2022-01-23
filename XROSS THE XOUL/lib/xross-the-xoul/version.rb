

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

    def =~(otra) = (self[:major] == otra.major) && (self[:minor] == otra.minor)

    # Comparisons where `#any?` success counts.
    ::Array[:>, :<].each { |method|
      define_method(method, ::Proc::new { |otra|
        self.values.zip(otra.values).any? { |ours, theirs|
          ours.send(method, theirs)
        }
      })
    }

    # Comparisons where `#all?` must be true.
    ::Array[:eql?, :>=, :<=].each { |method|
      define_method(method, ::Proc::new { |otra|
        self.values.zip(otra.values).all? { |ours, theirs|
          ours.send(method, theirs)
        }
      })
    }

    alias_method(:==, :eql?)

  }  # TripleCounter

end
