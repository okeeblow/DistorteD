class XROSS;            end
class XROSS::THE;       end
class XROSS::THE::XOUL; end

require_relative(-'xross-the-xoul/cpu') unless defined?(::XROSS::THE::CPU)
require_relative(-'xross-the-xoul/path') unless defined?(::XROSS::THE::PATH)
require_relative(-'xross-the-xoul/posix') unless defined?(::XROSS::THE::POSIX)
require_relative(-'xross-the-xoul/version') unless defined?(::XROSS::THE::Version)
