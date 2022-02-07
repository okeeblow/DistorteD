require(-'rbconfig')


# Host operating system detection.
class XROSS; end
class XROSS::THE; end
class XROSS::THE::OS

  # I used to check `RUBY_PLATFORM` alone until I learned about `RbConfig`:
  # https://idiosyncratic-ruby.com/42-ruby-config.html
  CHAIN = -case
  when defined?(::RbConfig::CONFIG) then
    # Created by `mkconfig.rb` when Ruby is built.
    ::RbConfig::CONFIG[-'host_os']
  when defined?(::RUBY_PLATFORM) then
    # This is misleading because it will be e.g. `'Java'` for JRuby,
    # and the paths we care about are more OS-dependent than Ruby-dependent.
    ::RUBY_PLATFORM
  when defined?(::ENV) && ::ENV&.has_key?(-'OS') then
    ::ENV[-'OS']  # I've seen examples where this is `'Windows_NT'` but don't expect it on *nix.
  else
    begin
      # Try to `require` something that will definitely fail on non-Windows:
      # https://ruby-doc.org/stdlib/libdoc/win32ole/rdoc/WIN32OLE.html
      require(-'win32ole') unless defined?(::WIN32OLE)
    rescue ::LoadError
      -'Winders'
    end
  end  # CHAIN

  # This is kinda redundant with `Gem.win_platform?`:
  # https://github.com/rubygems/rubygems/blob/master/lib/rubygems.rb Ctrl+F 'WIN_PATTERNS'
  def self.is_Winders?
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
  self.singleton_class.alias_method(:is_Windows?, :is_Winders?)

  def self.is_OS∕2?
    # This could also be DOS, but I'll assume OS∕2/ArcaOS 'cause I like it:
    # http://emx.sourceforge.net/
    # http://www.os2ezine.com/20020716/page_7.html
    (self::CHAIN =~ /emx/i) != nil
  end
  self.singleton_class.alias_method(:is_ArcaOS?, :is_OS∕2?)

  def self.is_macOS?
    (self::CHAIN =~ /darwin/i) != nil
  end

  def self.is_BSD?
    (self::CHAIN =~ /bsd/i) != nil
  end

  def self.is_Lunix?
    # LUNIX TRULY IS THE SUPERIOR OPERATING SYSTEM!!!1
    # http://www.somethingawful.com/jeffk/usar.swf
    (self::CHAIN =~ /linux/i) != nil
  end
  self.singleton_class.alias_method(:is_Linux?, :is_Lunix?)

end
