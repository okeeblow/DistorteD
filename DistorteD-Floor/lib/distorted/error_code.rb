# https://ruby-doc.org/core/Exception.html sez:
# "It is recommended that a library should have one subclass of StandardError
# or RuntimeError and have specific exception types inherit from it.
# This allows the user to rescue a generic exception type to catch
# all exceptions the library may raise even if future versions of
# the library add new exception subclasses."
class DistorteDError < StandardError; end

# Normal "File not found" errors are platform-specific, in the Errno module,
# so define our own generic one for DD:
# https://ruby-doc.org/core/IOError.html
# https://ruby-doc.org/core/Errno.html
class DistorteDFileNotFoundError < DistorteDError; end

# The built-in NotImplementedError is for "when a feature is not implemented
# on the current platform", so make our own more appropriate ones.
class MediaTypeNotImplementedError < DistorteDError
  attr_reader :name
  def initialize(name)
    super
    @name = name
  end

  def message
    "No supported media type for #{name}"
  end
end

class MediaTypeOutputNotImplementedError < MediaTypeNotImplementedError
  attr_reader :type, :context
  def initialize(name, type, context)
    super(name)
    @type = type
    @context = context
  end

  def message
    "Unable to save #{name} as #{type.to_s} from #{context}"
  end
end

class MediaTypeNotFoundError < DistorteDError
  attr_reader :name
  def initialize(name)
    super
    @name = name
  end

  def message
    "Failed to detect media type for #{name}"
  end
end


class OutOfDateLibraryError < LoadError; end
