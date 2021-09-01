require 'pathname' unless defined?(::Pathname)


# Cross-OS / Cross-Desktop / Cross-Ruby t00lz.
class ::CHECKING::YOU::OUT::XROSS_INFECTION

  # Host operating system detection.
  class SYSTEM
    require 'rbconfig'

    # I used to check `RUBY_PLATFORM` alone until I learned about `RbConfig`:
    # https://idiosyncratic-ruby.com/42-ruby-config.html
    CHAIN = -case
    when defined?(::RbConfig::CONFIG) then
      # Created by `mkconfig.rb` when Ruby is built.
      ::RbConfig::CONFIG[-'host_os']
    when defined?(RUBY_PLATFORM) then
      # This is misleading because it will be e.g. `'Java'` for JRuby,
      # and the paths we care about are more OS-dependent than Ruby-dependent.
      RUBY_PLATFORM
    when defined?(ENV) && ENV&.has_key?('OS') then
      ENV[-'OS']  # I've seen examples where this is `'Windows_NT'` but don't expect it on *nix.
    else
      begin
        # Try to `require` something that will definitely fail on non-Windows:
        # https://ruby-doc.org/stdlib/libdoc/win32ole/rdoc/WIN32OLE.html
        require 'win32ole'
      rescue ::LoadError
        'Winders'
      end
    end  # CHAIN

    # This is kinda redundant with `Gem.win_platform?`:
    # https://github.com/rubygems/rubygems/blob/master/lib/rubygems.rb Ctrl+F 'WIN_PATTERNS'
    def self.Windows?
      (self::CHAIN =~ %r&
        mswin|    # MS VC compiler / MS VC runtime
        mingw|    # GNU compiler  / MS VC runtime
        cygwin|   # GNU compiler / Cygwin POSIX runtime
        interix|  # GNU compiler / MS POSIX runtime
        bccwin|   # Borland C++ compiler and runtime (dead since Embarcadero C++ Builder uses Clang)
        windows|  # e.g. `ENV['OS']` can be `'Windows_NT'`
        wince|    # Can Ruby even run on CE? idk
        djgpp|    # http://www.delorie.com/djgpp/
        winders   # lol
      &xi) != nil || Gem.win_platform?
    end

    def self.OS∕2?
      # This could also be DOS, but I'll assume OS/2:
      # http://emx.sourceforge.net/
      # http://www.os2ezine.com/20020716/page_7.html
      (self::CHAIN =~ /emx/i) != nil
    end

    def self.macOS?
      (self::CHAIN =~ /darwin/i) != nil
    end

    def self.BSD?
      (self::CHAIN =~ /bsd/i) != nil
    end

    def self.Lunix?
      # LUNIX TRULY IS THE SUPERIOR OPERATING SYSTEM!!!1
      # http://www.somethingawful.com/jeffk/usar.swf
      (self::CHAIN =~ /linux/i) != nil
    end

    def self.Symmetry
      # Little-endian systems:
      # - VAX
      # - x86 / AMD64
      # Big-endian systems:
      # - Motorola 68k
      # - Internet https://en.wikipedia.org/wiki/Endianness#Networking
      # - IBM mainframes
      # Bi-endian systems:
      # - AArch64
      # - PowerPC / POWER
      # - MIPS
      # - Alpha
      # - PA-RISC
      # - SuperH
      # - Itanium
      # - RISC-V
      [1].yield_self { |bliss|
        # Pack the test Integer as a native-endianness 'I'nt and a 'N'etwork-endianess (BE) Int and compare.
        bliss.pack(-?I) == bliss.pack(-?N) ? :BE : :LE
      }
    end

  end  # SYSTEM


  # Our implementation of freedesktop-dot-org XDG directory handling:
  # https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
  #
  # There is a nice-looking Gem for this already: https://www.alchemists.io/projects/xdg/
  # However I'm not using it because CYO I want to do some nonstandard stuff ;)
  class XDG

    # Generic method to return absolute `Pathname`s for the contents of a given environment variable.
    def self.ENVIRONMENTAL_PATHNAMES(variable)
      # Skip empty-`String` variables as well as missing variables.
      if ENV.has_key?(variable) and not ENV[variable]&.empty?
        # `PATH_SEPARATE` will be a colon (:) on UNIX-like systems and semi-colon (;) on Windows.
        # Convert path variable contents to `Pathname`s with…
        # - :expand_path  —  Does shell expansion of path `String`s, e.g. `File.expand_path('~') == Dir::home`
        # - :directory?   —  Drop any expanded `Pathname`s that don't refer to extant directories.
        # - :realpath     —  Convert to absolute paths, e.g. following symbolic links.
        ENV[variable]
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
        if SYSTEM::mac? then
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
      self.DATA_HOME + self.DATA_DIRS
    end

    # Hide the `Pathname`-making helper method.
    private_class_method(:ENVIRONMENTAL_PATHNAMES)
  end  # XDG

end
