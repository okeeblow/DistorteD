require(-'pathname') unless defined?(::Pathname)
require(-'xross-the-xoul/os') unless defined?(::XROSS::THE::OS)


# Cross-OS / Cross-Desktop / Cross-Ruby t00lz.
class ::CHECKING::YOU::OUT::XROSS_INFECTION

  # Our implementation of freedesktop-dot-org XDG directory handling:
  # https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
  #
  # There is a nice-looking Gem for this already: https://www.alchemists.io/projects/xdg/
  # However I'm not using it because CYO I want to do some nonstandard stuff ;)
  class XDG

    # TODO: Eliminate this once `::ENV` is shareable on its own: https://bugs.ruby-lang.org/issues/17676
    DD_ENV = ::Ractor::make_shareable(::Hash::new.merge(::ENV))

    # Generic method to return absolute `Pathname`s for the contents of a given environment variable.
    def self.ENVIRONMENTAL_PATHNAMES(variable)
      # Skip empty-`String` variables as well as missing variables.
      if DD_ENV.has_key?(variable) and not DD_ENV[variable]&.empty?
        # `PATH_SEPARATE` will be a colon (:) on UNIX-like systems and semi-colon (;) on Windows.
        # Convert path variable contents to `Pathname`s with…
        # - :expand_path  —  Does shell expansion of path `String`s, e.g. `File.expand_path('~') == Dir::home`
        # - :directory?   —  Drop any expanded `Pathname`s that don't refer to extant directories.
        # - :realpath     —  Convert to absolute paths, e.g. following symbolic links.
        DD_ENV[variable]
          .split(::File::PATH_SEPARATOR)
          .map(&::Pathname::method(:new))
          .map(&:expand_path)
          .keep_if(&:directory?)
          .map(&:realpath)
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
  end  # XDG

end
