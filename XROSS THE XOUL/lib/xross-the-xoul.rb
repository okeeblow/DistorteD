class XROSS;            end
class XROSS::THE;       end
class XROSS::THE::XOUL; end

require_relative(-'xross-the-xoul/cpu') unless defined?(::XROSS::THE::CPU)
require_relative(-'xross-the-xoul/desktop') unless defined?(::XROSS::THE::DESKTOP)
require_relative(-'xross-the-xoul/posix') unless defined?(::XROSS::THE::POSIX)
