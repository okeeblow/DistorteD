require(-'pathname') unless defined?(::Pathname)

require_relative(-'os') unless defined?(::XROSS::THE::OS)


# Components for cross-Desktop `::Pathname` resolution, e.g. directories for configuration, data, cache, etc.
# This is mostly an implementation of the freedesktop-dot-org (originally XDG, for "Cross Desktop Group")
# 'basedir' specification: https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
#
# More info/history:
# https://www.freedesktop.org/wiki/Specifications/
# https://specifications.freedesktop.org/
# https://gitlab.freedesktop.org/xdg/xdg-specs
# https://lwn.net/2000/0427/a/freedesktop.html
#
# There is a nice-looking Gem for this already: https://www.alchemists.io/projects/xdg/
# However I'm not using it because I don't like having to instantiate `::XDG::Environment` first
# and because I want to do some stuff beyond the standard such as paths for Windows/macOS.
class XROSS; end
class XROSS::THE; end
class XROSS::THE::PATH

  # TODO: Eliminate this once `::ENV` is shareable on its own: https://bugs.ruby-lang.org/issues/17676
  self::DD_ENV = ::Ractor::make_shareable(::Hash::new.merge(::ENV))

  # Generic method to return absolute `Pathname`s for the contents of a given environment variable.
  #
  # Per https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html —
  # "All paths set in these environment variables must be absolute. If an implementation encounters
  #  a relative path in any of these variables it should consider the path invalid and ignore it."
  # I don't really like this, but we should match the behavior of XDG by default anyway.
  #
  # I'm also going to `#expand_path` for the "_HOME" XDG variables (e.g. `$XDG_DATA_HOME`, `$XDG_BIN_HOME`, etc)
  # since they're likely to be defined with a relative reference to the homedir path.
  #
  # Note the difference in behavior between "home" as a shell expansion (the tilde / `~`), vs as an exported
  # variable (`$HOME`) interpreted by our shell, vs as a variable name passed in as a raw `::String`:
  #
  #   [okeeblow@emi#CHECKING YOU OUT] TESTVAR=$HOME/hello.jpg ruby -e "p ENV['TESTVAR']"
  #   "/home/okeeblow/hello.jpg"
  #   [okeeblow@emi#CHECKING YOU OUT] TESTVAR="$HOME/hello.jpg" ruby -e "p ENV['TESTVAR']"
  #   "/home/okeeblow/hello.jpg"
  #   [okeeblow@emi#CHECKING YOU OUT] TESTVAR='$HOME/hello.jpg' ruby -e "p ENV['TESTVAR']"
  #   "$HOME/hello.jpg"
  #   [okeeblow@emi#CHECKING YOU OUT] TESTVAR='$HOME/hello.jpg' ruby -r 'optionparser' -e "p OptionParser::new.environment('TESTVAR')"
  #   ["$HOME/hello.jpg"]
  #   [okeeblow@emi#CHECKING YOU OUT] TESTVAR='~/hello.jpg' ruby -e "p ENV['TESTVAR']"
  #   "~/hello.jpg"
  #   [okeeblow@emi#CHECKING YOU OUT] TESTVAR='~okeeblow/hello.jpg' ruby -e "p ENV['TESTVAR']"
  #   "~okeeblow/hello.jpg"
  #   [okeeblow@emi#CHECKING YOU OUT] TESTVAR='~/hello.jpg' ruby -r 'pathname' -e "p ::Pathname::new(ENV['TESTVAR']).expand_path"
  #   #<Pathname:/home/okeeblow/hello.jpg>
  #   [okeeblow@emi#CHECKING YOU OUT] TESTVAR='~okeeblow/hello.jpg' ruby -r 'pathname' -e "p ::Pathname::new(ENV['TESTVAR']).expand_path"
  #   #<Pathname:/home/okeeblow/hello.jpg>
  #   [okeeblow@emi#CHECKING YOU OUT] TESTVAR='$HOME/hello.jpg' ruby -r 'pathname' -e "p ::Pathname::new(ENV['TESTVAR']).expand_path"
  #   #<Pathname:/home/okeeblow/Works/DistorteD/CHECKING YOU OUT/$HOME/hello.jpg>
  #
  # I'm not going to attempt to interpret raw variable-name `::String`s (like `'$HOME'`) for now.
  def self.ENVIRONMENTAL_PATHNAMES(variable, allow_relative = false)
    # Skip empty-`String` variables as well as missing variables.
    # Helper methods should provide appropriate defaults when we fail this condition and return `nil`.
    if self::DD_ENV.has_key?(variable) and not self::DD_ENV[variable]&.empty?
      # `PATH_SEPARATOR` will be a colon (:) on UNIX-like systems and semi-colon (;) on Windows.
      # Convert path variable contents to `Pathname`s with…
      # - :expand_path  —  Does shell expansion of path `String`s, e.g. `File.expand_path('~') == Dir::home`
      # - :directory?   —  Drop any expanded `Pathname`s that don't refer to extant directories.
      # - :realpath     —  Follow symbolic links and expand dots (`.` and `..`) if `#expand_path` didn't already.
      #                    Raises `Errno::ENOENT` for nonexistent paths, so `#keep_if(&:directory)` must come first.
      self::DD_ENV[variable]
        .split(::File::PATH_SEPARATOR)
        .map!(&::Pathname::method(:new))
        .send((allow_relative or variable.end_with?(-'_HOME') ? :map! : :itself), &:expand_path)
        .keep_if(&:directory?)
        .map!(&:realpath)
    end
  end

  # "`$XDG_DATA_DIRS` defines the preference-ordered set of base directories to
  # search for data files in addition to the `$XDG_DATA_HOME` base directory."
  def self.DATA_DIRS
    # "If `$XDG_DATA_DIRS` is either not set or empty,
    # a value equal to `/usr/local/share/:/usr/share/` should be used."
    self.ENVIRONMENTAL_PATHNAMES(-'XDG_DATA_DIRS') || ['/usr/local/share/', '/usr/share/'].tap {
      # Fixup platforms where we know to expect filez outside the fd.o defaults.
      if ::XROSS::THE::OS::mac? then
        _1.append('/opt/homebrew/share/')  # Homebrew
        _1.append('/opt/local/share/')     # MacPorts
      end
    }.map(&::Pathname::method(:new)).keep_if(&:directory?).map(&:realpath)
  end  # DATA_DIRS

  # "`$XDG_DATA_HOME` defines the base directory relative to which user-specific data files should be stored."
  def self.DATA_HOME
    self.ENVIRONMENTAL_PATHNAMES(-'XDG_DATA_HOME') || [
      # "If `$XDG_DATA_HOME` is either not set or empty, a default equal to $HOME/.local/share should be used."
      ::Pathname.new(::Dir::home).expand_path.realpath.join(-'.local', -'share')
    ]
  end

  # "`$XDG_CONFIG_HOME` defines the base directory relative to which user-specific configuration files should be stored."
  def self.CONFIG_HOME
    self.ENVIRONMENTAL_PATHNAMES(-'XDG_CONFIG_HOME') || [
      # "If `$XDG_CONFIG_HOME` is either not set or empty, a default equal to `$HOME/.config` should be used."
      ::Pathname.new(::Dir::home).expand_path.realpath.join(-'.config')
    ]
  end

  # "`$XDG_STATE_HOME` defines the base directory relative to which user-specific state files should be stored."
  def self.STATE_HOME
    self.ENVIRONMENTAL_PATHNAMES(-'XDG_STATE_HOME') || [
      # "If `$XDG_STATE_HOME` is either not set or empty, a default equal to `$HOME/.local/state` should be used. "
      ::Pathname.new(::Dir::home).expand_path.realpath.join(-'.local', -'state')
    ]
  end

  # Returns a combined `Array` of user-specific and system-wide XDG Data `Pathname`s.
  def self.DATA
    # The base directory defined by `$XDG_DATA_HOME` is considered more important
    # than any of the base directories defined by `$XDG_DATA_DIRS`.
    self.DATA_DIRS + self.DATA_HOME
  end

  # Hide the `Pathname`-making helper method.
  private_class_method(:ENVIRONMENTAL_PATHNAMES)

end
