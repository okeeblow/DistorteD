require(-'pathname') unless defined?(::Pathname)

require_relative(-'astraia_no_soubei') unless defined?(::CHECKING::YOU::OUT::ASTRAIAの双皿)

# Provide case-optional `::String`-like keys for Postfix and Glob filename fragments.
#
# From Ruby's `::Hash` docs: "Two objects refer to the same hash key when their hash value is identical
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
::CHECKING::YOU::OUT::DeusDextera = ::Class::new(::CHECKING::YOU::OUT::ASTRAIAの双皿) do

  # Return our case-sensitive `String` variation iff we are marked case-sensitive *and* have a `String` value,
  # otherwise just return our frozen deduplicated `self` value.
  def itself
    instance_variable_get(:@case_sensitive)&.is_a?(::String) ? instance_variable_get(:@case_sensitive) : self
  end

  # Convert a `*.extname`-style `::String` glob into an instance of us.
  # The most significant `extname` will be our `#first` member,
  # so we can be easily splatted into a `#dig` in another container.
  def self.from_string(otra)
    raise(
      ::ArgumentError,
      'string format must be `*.extname`, e.g. `*.jpg` or `*.txt`'
    ) unless otra.start_with?(-'*.') and otra.count(-?*).eql?(1) and otra.count(-?.).eql?(1)
    self.new(otra)
  end

  # Ruby language convention for conversion of an unknown other.
  def self.try_convert(otra) = otra.is_a?(::String) ? self.from_string(otra) : super(otra)

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
      when self.class then otra.to_s
      when ::Symbol   then otra.to_s  # Assume `::Symbol` is an extname. `::Symbol#name` is frozen — `#to_s` is not.
      when ::Pathname then otra.extname.empty? ? otra.basename.to_s : otra.extname
      when ::String   then
        if ::File::extname(otra).empty? then
          otra.start_with?(-?.) ? otra : ::File::basename(otra)
        else
          # This will also catch Glob-style `::String`s like `*.zip` since the `*` counts as the `#basename`:
          #   irb> ::File::extname("*.zip") => ".zip"
          ::File::extname(otra)
        end
      else otra.to_s
    end.yield_self {
      # Make ourself into a Glob-style `::String` if we aren't already,
      # for easy comparison later using `::File::fnmatch`.
      _1.start_with?(-'*.') ? _1 :
        _1.insert(0, (_1.ord.eql?(46) ? -?* : -'*.'))
    }.-@

    # The `super` call in this condition statement will explicitly set the `self` value to the downcased version of our key,
    # but we will then compare `super`'s return value to its input to decide if we should store a case-sensitive value too.
    #
    # If the computed key is already downcase we could still be case-sensitive if we were boolean-marked as such,
    # otherwise we have no need for the IVar and can remove it if one is set.
    #
    # Explicitly check if the IVar == `true`, not just truthiness, because it may also be a `String`
    # if we are `#replace`ing a previous case-sensitive value.
    #
    # NOTE: There is a hole in the logic here where any non-downcased input will cause case-sensitivity,
    # but this is necessary since our XML parsing might give us a `pattern` attribute callback
    # before we'd had a chance to set a `case-insensitive` mark.
    # All of the `case-sensitive="true"` `<glob>`s in current fd.o XML have an upper-case component,
    # so this hack will make sure we don't discard the proper-cased `String` if we see that callback before the mark.
    if (super(-newbuild.downcase(:fold)) != newbuild) or case_sensitive or (instance_variable_get(:@case_sensitive) == true) then
      instance_variable_set(:@case_sensitive, newbuild)
    else
      remove_instance_variable(:@case_sensitive) if instance_variable_defined?(:@case_sensitive)
    end
    self  # return the new downcased value we just set when we called `super`
  end  # replace

  # We represent a single right-hand-side `extname`.
  def sinistar? = true

  # Always return a new instance so we don't get caught out with a `#clear` by reference.
  def sinistar  = self.dup

  # Our instance value was derived from a Glob `::String`,
  # and we should provide an alias to signal our support for the reverse.
  # This overrides an inherited alias to `#to_s` to handle case-sensitive extnames.
  alias_method(:to_glob, :itself)

  # Explicit…
  alias_method(:to_s, :itself)
  # …and implicit `::String` conversion.
  alias_method(:to_str, :itself)

end
