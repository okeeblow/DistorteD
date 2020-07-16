# https://ruby-doc.org/core/Exception.html sez:
# "It is recommended that a library should have one subclass of StandardError
# or RuntimeError and have specific exception types inherit from it.
# This allows the user to rescue a generic exception type to catch
# all exceptions the library may raise even if future versions of
# the library add new exception subclasses."
class StandardDistorteDError < StandardError
end
