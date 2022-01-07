require('xross-the-xoul/posix/glob') unless defined?(::XROSS::THE::POSIX::Glob)

require_relative(-'../weighted_action') unless defined?(::CHECKING::YOU::OUT::WeightedAction)


::CHECKING::YOU::OUT::ASTRAIAの双皿 = ::Class::new(::String) do

  # Be case-insensitive by default so we can match any filename.
  DEFAULT_SENSITIVITY = false

  # These may be weighted just like byte sequences.
  include(::CHECKING::YOU::OUT::WeightedAction)

  # This class needs to support being instantiated without a value due to the way our XML data gets loaded,
  # but the superclass `String` has a default `str=""` argument here that works perfectly for that need.
  def initialize(str=-'', *args, case_sensitive: DEFAULT_SENSITIVITY, **kwargs)
    # Prime `#replace` to treat its next `String` as case-sensitive iff we were told.
    instance_variable_set(:@case_sensitive, case_sensitive) if case_sensitive == true

    # Don't pass an initial `str` value to `super` if we were given one,
    # because `#replace` has case-sensitivity-handling functionality that must be called.
    super(nil.to_s, *args, capacity: str.to_s.size, **kwargs)
    self.replace(str) unless str.empty?
  end

  # Globs are similar to but not directly comparable with `::Regexp`,
  # but we have a support library that handles the conversion.
  #
  # `#to_regexp` is the method which will be used by `::Regexp::try_convert`.
  def to_regexp(flags = 0) = ::XROSS::THE::POSIX::Glob::to_regexp(self, flags)

  # We're already a Glob.
  def to_glob = self.to_s

  # Mark intent to be case-sensitive. Our source data's `<glob>` Attributes are parsed one at a time,
  # so we won't know at the time of instantiation if we want to be case sensitive.
  def case_sensitive=(sensitivity)
    # Don't bother allocating an IVar if we're just going to be the default (case-insensitive)
    if sensitivity == false then
      remove_instance_variable(:@case_sensitive) if instance_variable_defined?(:@case_sensitive)
    else
      instance_variable_set(:@case_sensitive, sensitivity)
    end
  end

  # Return our case-sensitive `String` variation iff one exists, otherwise `nil`.
  def case_sensitive
    instance_variable_get(:@case_sensitive)&.is_a?(::String) ? instance_variable_get(:@case_sensitive) : nil
  end

  # Return a boolean describing our case-sensitivity status.
  def case_sensitive?
    # The same-name IVar could contain a (non-default) boolean value, but it's far more likely to contain
    # the desired-case variation of the `self` String. In that case this returns `true` instead of the value.
    case instance_variable_get(:@case_sensitive)
      when ::String    then true   # We have stored a String case-variation.
      when ::TrueClass then true   # We have been marked for case-sensitivity next `#replace`.
      else                  false  # NilClass, FalseClass, or anything else.
    end
  end

  def clear
    remove_instance_variable(:@case_sensitive) if instance_variable_defined?(:@case_sensitive)
    super  # Calls `WeightedAction#clear` and any others in the ancestor chain.
  end

  # Returns case-optional boolean equality between this `StellaSinistra` and a given object `StellaSinistra` or `String`.
  # This is one of two methods necessary for matching Hash keys, but this method will be called only if `self#hash`
  # and `otra#hash` return the same Integer value, complicated by the fact that MRI's C implementation of `rb_str_hash_cmp`
  # won't use our overriden version of `#hash`.
  # That's why we downcase ourselves in `#replace` and store case variations separately.
  def eql?(otra)
    # https://ruby-doc.org/core/File.html#method-c-fnmatch-3F
    #
    # The `File` Class has kinda-poorly-documented Integer constants to control the behavior of `File::fnmatch?`.
    # If this feels non-Ruby-ish it's because this is a POSIX thing:
    # https://pubs.opengroup.org/onlinepubs/9699919799/functions/fnmatch.html
    #
    #   irb(main):061:0> File::constants::keep_if { _1.to_s.include?('FNM_') }
    #   => [:FNM_CASEFOLD, :FNM_EXTGLOB, :FNM_SYSCASE, :FNM_NOESCAPE, :FNM_PATHNAME, :FNM_DOTMATCH, :FNM_SHORTNAME]
    #   irb(main):062:0> File::constants::keep_if { _1.to_s.include?('FNM_') }.map(&File::method(:const_get))
    #   => [8, 16, 0, 1, 2, 4, 0]
    #
    #
    # - `File::FNM_PATHNAME` controls wildcards in the haystack matching `File::SEPARATOR` in the needle:
    #
    #   irb> File.fnmatch?('*.jpg', '/hello.jpg', File::FNM_PATHNAME)
    #   => false
    #   irb> File.fnmatch?('*.jpg', '/hello.jpg')
    #   => true
    #   irb> File.fnmatch?('*.jpg', 'hello.jpg', File::FNM_PATHNAME)
    #   => true
    #   irb> File.fnmatch?('*.jpg', 'hello.jpg')
    #   => true
    #
    #
    # - `File::FNM_DOTMATCH` controls wildcard in the haystack matching `.` in the needle, like *nix-style "hidden" files:
    #
    #   irb> File.fnmatch?('*.jpg', '.hello.jpg', File::FNM_DOTMATCH)
    #   => true
    #   irb> File.fnmatch?('*.jpg', '.hello.jpg')
    #   => false
    #
    #
    # - `File::FNM_EXTGLOB` controls support for brace-delimited glob syntax for haystacks:
    #
    #   irb> File.fnmatch?('*.jp{e,}g', 'hello.jpg', File::FNM_EXTGLOB)
    #   => true
    #   irb> File.fnmatch?('*.jp{e,}g', 'hello.jpeg', File::FNM_EXTGLOB)
    #   => true
    #   irb> File.fnmatch?('*.jp{e,}g', 'hello.jpeg')
    #   => false
    #   irb> File.fnmatch?('*.jp{e,}g', 'hello.jpg')
    #   => false
    #
    #
    # - `File::FNM_CASEFOLD` and `File::FNM_SYSCASE` control the case-sensitivity when matching,
    #   either by folding (explicit case-insensitivity) or by matching the behavior of the host operating system,
    #   *not* the behavior of any specific filesystem on that OS (https://bugs.ruby-lang.org/issues/15363),
    #   e.g. case-sensitive on BSD/Linux:
    #
    #   irb> RUBY_PLATFORM
    #   => "x86_64-linux"
    #   irb> File.fnmatch?('LOICENSE', 'loicense', File::FNM_SYSCASE)
    #   => false
    #   irb> File.fnmatch?('LOICENSE', 'loicense', File::FNM_CASEFOLD)
    #   => true
    #   irb> File.fnmatch?('LOICENSE', 'loicense')
    #   => false
    #
    #
    # - `File::FNM_NOESCAPE` (ominously) controls matching escape sequences literally:
    #   https://github.com/ruby/ruby/blob/master/doc/syntax/literals.rdoc#label-Strings
    #
    #   irb> File.fnmatch?("*.jpg\\", 'hello.jpg', File::FNM_NOESCAPE)
    #   => false
    #   irb> File.fnmatch?("*.jpg\\", 'hello.jpg')
    #   => true
    #
    #
    # - `File::FNM_SHORTNAME` seems to control eight-dot-three filename matching, per the documentation:
    #   "Makes patterns to match short names if existing. Valid only on Microsoft Windows."
    #
    #
    # - Multiple of these Integer Constants can be bitwise-`OR`ed together for simultaneous use:
    #
    #   irb> File.fnmatch?('*.jp{e,}g', '/root/.HeLlO.jPEg', File::FNM_EXTGLOB | File::FNM_CASEFOLD | File::FNM_DOTMATCH)
    #   => true
    #   irb> File.fnmatch?('*.jp{e,}g', '/root/.HeLlO.jPEg', File::FNM_EXTGLOB | File::FNM_CASEFOLD | File::FNM_DOTMATCH | File::FNM_PATHNAME)
    #   => false
    ::File.fnmatch?(
      self.to_s,              # Haystack
      otra.to_s,              # Needle
      ::File::FNM_DOTMATCH  |
        ::File::FNM_EXTGLOB |
        (
          # Support testing `otra` as either another `StellaSinistra` or as a plain `String`,
          # in which case it will not have a method `#case_sensitive?`.
          # Use our own case-sensitivity setting when comparing against plain `Strings`.
          (self.case_sensitive? or (otra.respond_to?(:case_sensitive?) ? otra.case_sensitive? : self.case_sensitive?)) ?
          0 : ::File::FNM_CASEFOLD
        )
    )
  end  # eql?

  # `Hash`-key usage depends on `#eql?`, but `:==` should have identical behavior for our own uses.
  alias_method(:==, :eql?)

  # Return a boolean describing if we are a single-extname only vs. if we are a more complex glob.
  def sinistar? = (self.start_with?(-'*.') and self.count(-?*).eql?(1))

  # Convert this generic Glob-`::String` instance into a new more-appropriate `::Object`.
  def sinistar
    if self.start_with?(-'*.') and self.count(?*).eql?(1) and self.count(?.).eql?(1) then
      # Single `extname`s (e.g. `*.jpg`) can be a single `::String` subclass instance.
      ::CHECKING::YOU::OUT::DeusDextera::new(self.delete_prefix(-'*.').-@)
    elsif self.start_with?(-'*.') then
      # Multi-`extname`s (e.g. `*.tar.bz2`) will be an `::Array` subclass instance
      # of `::String` subclasses instances.
      ::CHECKING::YOU::OUT::StellaSinistra[
        *self.delete_prefix(-'*.').split(?.).reverse!.map!(&:-@)
      ].map!(&::CHECKING::YOU::OUT::DeusDextera::method(:new))
    else
      # And anything else (freeform globs) will be a new instance of us.
      self.class.new(self)
    end
  end


end
