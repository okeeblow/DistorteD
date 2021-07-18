require 'pathname' unless defined?(::Pathname)


class CHECKING::YOU
  # Provide case-optional String-like keys for Postfixes, Globs, etc.
  #
  # From Ruby's `Hash` docs: "Two objects refer to the same hash key when their hash value is identical
  # and the two objects are eql? to each other"
  # I tried to subclass String and just override `:eql?` and `:hash` for case-insensitive lookups,
  # but it turns out not be that easy due to MRI's C comparison functions for String, Symbol, etc.
  #
  # It was super-confusing because I could call e.g. `'DOC'.eql? 'doc'` manually and get `true`,
  # but it would always fail to work when used as a `Hash` key, when calling `uniq`, or in a `Set`:
  #
  # irb(main):049:1* Lol = Class.new(String).tap {
  # irb(main):050:1*   _1.define_method(:hash) do; self[0..5].downcase!.hash; end;
  # irb(main):051:1*   _1.define_method(:eql?) do |lol|; self[0..5].casecmp?(lol[0..5]); end;
  # irb(main):052:1*   _1.alias_method(:==, :eql?)
  # irb(main):053:0> }
  # irb(main):054:0> fart = Lol.new("abcdefg")
  # irb(main):055:0> butt = Lol.new("abcdefgh")
  # irb(main):056:0> fart == butt
  # => true
  # irb(main):057:0> fart.eql? butt
  # => true
  # irb(main):058:0> fart.hash
  # => 1243221847611081438
  # irb(main):059:0> butt.hash
  # => 1243221847611081438
  # irb(main):060:0> {fart => "smella"}[butt]
  # => nil
  # irb(main):061:0> {fart => "smella"}[fart]
  # => "smella"
  #
  # I'm not the first to run into this, as I found when searching for `"rb_str_hash_cmp"`:
  # https://kate.io/blog/strange-hash-instances-in-ruby/
  #
  # To work around this I will explicitly `downcase` the actual String subclass' value
  # and just let the hashes collide for differently-cased values, then `eql?` will decide.
  # This is still slower than the all-C String code but is the fastest method I've found
  # to achieve this without doubling my Object allocations by wrapping each String in a Struct.
  StickAround = Class.new(::String) do

    # Be case-insensitive by default so we can match any filename.
    DEFAULT_SENSITIVITY = false

    # These may be weighted just like byte sequences.
    include WeightedAction

    # This class needs to support being instantiated without a value due to the way our XML data gets loaded,
    # but the superclass `String` has a default `str=""` argument here that works perfectly for that need.
    def initialize(*args, case_sensitive: DEFAULT_SENSITIVITY, **kwargs)
      instance_variable_set(:@case_sensitive, case_sensitive) if case_sensitive == true
      super(*args, **kwargs)
    end

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

    # Return our case-sensitive String variation iff we are marked case-sensitive *and* have a String value,
    # otherwise just return our frozen deduplicated self value.
    def itself
      instance_variable_get(:@case_sensitive)&.is_a?(::String) ? instance_variable_get(:@case_sensitive) : self
    end

    def case_sensitive
      instance_variable_get(:@case_sensitive)&.is_a?(::String) ? instance_variable_get(:@case_sensitive) : nil
    end

    # Set an appropriate value for ourselves given a variety of input.
    # Even though this is called `#replace` here and in `String`, this method will often be used
    # to set initial instance values due to nondeterministic attribute order while parsing our XML data.
    def replace(otra, case_sensitive: DEFAULT_SENSITIVITY)
      # Extract a usable value from different input types/formats.
      #
      # `File::extname` will return the last dotted component of a String, prepended with the leading dot,
      #  e.g. `File::extname("hello.jpg")` => `".jpg"`. We will prepend an asterisk to these to make a glob pattern.
      #
      # `File::extname` will be an empty String for input Strings which contain no dotted components
      #  or only have a leading dot, e.g. `File::extname(".bash_profile") => `""`.
      newbuild = case otra
        when self.class then -otra.to_s
        when ::Symbol   then -otra.to_s  # TODO: Ruby 3.0 Symbol#name
        when ::Pathname then otra.extname.empty? ? otra.basename.to_s.-@ : otra.extname.prepend(-?*).-@
        when ::String   then (File.extname(otra).empty? or -otra[-1] == -?*) ? -otra : -File.extname(otra).prepend(-?*)
        else -otra.to_s
      end

      # The `super` call in this condition statement will explicitly set the `self` value to the downcased version of our key,
      # but we will then compare `super`'s return value to its input to decide if we should store a case-sensitive value too.
      #
      # If the computed key is already downcase we could still be case-sensitive if we were boolean-marked as such,
      # otherwise we have no need for the IVar and can remove it if one is set.
      if super(-newbuild.downcase(:fold)) === newbuild or (case_sensitive == false and instance_variable_get(:@case_sensitive) != true)
        remove_instance_variable(:@case_sensitive) if instance_variable_defined?(:@case_sensitive)
      else
        instance_variable_set(:@case_sensitive, newbuild)
      end
      self
    end  # replace

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

    # Returns case-optional boolean equality between this `StickAround` and a given object `StickAround` or `String`.
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
      File.fnmatch?(
        self.itself,           # Haystack
        otra.itself,           # Needle
        File::FNM_DOTMATCH  |
          File::FNM_EXTGLOB |
          (self.case_sensitive? ? 0 : File::FNM_CASEFOLD)
      )
    end  # eql?

    # Hash-key usage depends on `#eql?`, but `:==` should have identical behavior for our own uses.
    alias_method(:==, :eql?)

    # Return an Integer hash value for this object. This method and `#eql?` are used by `Hash`, `Set`, and `#uniq` to
    # associate separate Objects with each other for deduplication or for use as `Hash` keys.
    # The `eql?` method will be called only *after* two Integer `#hash` values match!
    #
    # NOTE: MRI will not use this function in many cases!
    # It has C implementations of methods like `rb_str_hash_cmp` for `Hash` lookups, and this is usually a Good Thing™
    # since it makes `Hash`es fast when using `String` or `Symbol` as keys.
    # Subclassing built-in types like `String` allows/forces us to use these same accelerated code paths,
    # and it was incredibly confusing for me why my custom String subclass was behaving so strangely
    # when used as a Hash key until I had a hunch to read MRI's `string.c` and `hash.c` and confirmed.
    # I found this write-up once I knew to search for "rb_str_hash_cmp": https://kate.io/blog/strange-hash-instances-in-ruby/
    #
    # I'm going to define this anyway because it could still be useful in certain corner cases, but be aware of the above!
    # This is the reason I explicitly `downcase` our self value in `#replace`, because otherwise the Hash keys will never match
    # and `#eql?` will never even be called.
    def hash
      if self.include?(-?*) and not self.start_with?(-?*) then self[...6].downcase!.hash
      elsif self.include?(-?*) and not File.extname(self).empty? then File.extname(self).delete_prefix!(-?.)
      else super
      end
    end

  end  # StickAround
end  # class CHECKING::YOU
