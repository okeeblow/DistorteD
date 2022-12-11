# This is how we're testing.
require('bundler/setup')
require('test/unit') unless defined?(::Test::Unit)

# This is what we're testing.
require_relative('../lib/globeglitter') unless defined?(::GlobeGlitter)

# Use `Kernel#load` for discovered tests instead of `Kernel#require` or `#require_relative`,
# because `#load` supports paths relative to CWD in addition to just to `$LOAD_PATH` (like `#require`)
# or to `__file__` (like `#require_relative`).
# This lets me have a nice easy entry-point in `GEM_ROOT/bin` instead of having to `cd` in first.
#
# These files should contain a subclass of `Test::Unit::TestCase` with methods named like `test_whatever`
# which `test/unit` will automatically discover and execute as long as they're loaded.
Dir.glob("**/tmb_*.rb").each { load _1 }

# Built-in assertion methods are listed here:
# https://www.rubydoc.info/github/test-unit/test-unit/Test/Unit/Assertions
