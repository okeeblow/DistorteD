# https://ruby-doc.org/core/Exception.html sez:
# "It is recommended that a library should have one subclass of StandardError
# or RuntimeError and have specific exception types inherit from it.
# This allows the user to rescue a generic exception type to catch
# all exceptions the library may raise even if future versions of
# the library add new exception subclasses."
class StandardDistorteDError < StandardError
end

# The built-in NotImplementedError is for "when a feature is not implemented
# on the current platform", so make our own more appropriate ones.
class MediaTypeNotImplementedError < StandardDistorteDError
  attr_reader :name
  def initialize(name)
    super("No supported media type for #{name}")
    super
    @name = name
  end

  def message
    "No supported media type for #{name}"
  end
end
  end
end

class MediaTypeNotFoundError < StandardDistorteDError
  attr_reader :name
  def initialize(name)
    super
    @name = name
  end

  def message
    "Failed to detect media type for #{name}"
  end
end


class OutOfDateLibraryError < LoadError
end
