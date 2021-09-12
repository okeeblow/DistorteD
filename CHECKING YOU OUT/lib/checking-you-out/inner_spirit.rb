require(-'set') unless defined?(::Set)
require(-'pathname') unless defined?(::Pathname)


# This base Struct will be used as the Hash key for its matching `OUT` subclass object,
# and its members correspond to the three major parts of an IETF "Content-Type" String,
# e.g. "application/x-saturn-rom" → :x, :application, :"saturn-rom".
#
# This is kind of a leaky abstraction since I want to support non-IETF type systems too,
# but the IETF system is by far the most relevant one to us because the most exhaustive
# source data (`shared-mime-info`) is based on that format and because, you know, Internet.
# See the adjacent `auslandsgespräch.rb` for the parser and more info.
#
#
# The instances of a `Struct` subclass with at most `RSTRUCT_EMBED_LEN_MAX` members
# can fit entirely within an `RStruct` without additional heap allocation.
# In MRI (at least as of 3.0) the `RSTRUCT_EMBED_LEN_MAX` is 3, so CYI uses three members.
#
# For more info see:
# - https://github.com/ruby/ruby/blob/master/gc.c
# - http://patshaughnessy.net/2013/2/8/ruby-mri-source-code-idioms-3-embedded-objects
class ::CHECKING; end
class ::CHECKING::YOU; end
::CHECKING::YOU::IN = ::Struct.new(
  # Intentionally avoiding naming taxonomic ranks like "domain", "class", or "order"
  # whose names are already common in computing.
  :kingdom,
  :phylum,
  :genus,
) do

  # Default `::Ractor` CYO data area name.
  # This will be the area used for all synchronous method invocations that do not specify otherwise.
  self::DEFAULT_AREA_CODE = -'CHECKING YOU OUT'

  # Symbolize our `::Struct` values if they're given separately (not as a CYI/CYO).
  def initialize(*taxa)
    super(*(taxa.first.is_a?(::CHECKING::YOU::IN) ? taxa.first : taxa.map!(&:to_sym)))
  end

  # Promote any CYI to its CYO singleton. CYO has the opposites of these methods.
  def out(area_code: self.class::DEFAULT_AREA_CODE)
    self.class.areas[area_code].send(self)
    ::Ractor.receive
  end
  def in; self; end

  # e.g. irb> CYI::from_ietf_media_type('image/jpeg') == 'image/jpeg' => true
  def eql?(otra)
    case otra
    when ::String then self.to_s.eql?(otra)
    when ::CHECKING::YOU::IN, ::CHECKING::YOU::OUT then self.values.eql?(otra.values)
    else super(otra)
    end
  end
  alias_method(:==, :eql?)
end

# Main Struct subclass for in-memory type representation.
# Instances of the base `CHECKING::YOU::IN` Struct will refer to only one of these,
# and this matching object will contain all relevant data about the type,
# such as file extension(s), `magic` bytes, and variations of a base type like all of:
# - "application/vnd.wordperfect;"
# - "application/vnd.wordperfect;version=4.2"
# - "application/vnd.wordperfect;version=5.0"
# - "application/vnd.wordperfect;version=5.1"
# - "application/vnd.wordperfect;version=6.x"
# …will be represented in a single `CHECKING::YOU::OUT` object.
class ::CHECKING::YOU::OUT < ::CHECKING::YOU::IN

  # Absolute path to the root of the Gem — the directory containing `bin`,`docs`,`lib`, etc.
  GEM_ROOT = proc { ::Pathname.new(__dir__).join(*::Array.new(2, -'..')).expand_path.realpath }

  # Time object representing the day this running CYO Gem was packaged.
  #
  # `Gem::Specification#date` can be slightly misleading when developing locally with Bundler using `bundle exec`.
  # One might expect the result of `#date` to be "now" (including hours/minutes/seconds) in UTC for such a runtime-packaged Gem,
  # but it will always be midnight UTC of the current day (also in UTC), i.e. a date that is always[0] in the past.
  #
  # After ${your-UTC-offset} hours before midnight localtime, this will give you a *day* that seems to be in the future
  # compared to a system clock displaying localtime despite that *date* UTC still being in the past,
  # e.g. as I write this comment at 2021-05-25 22:22 PST, `GEM_PACKAGE_TIME.call` returns `2021-05-26 00:00:00 UTC`.
  #
  # Rescue from `Gem::MissingSpecError`'s parent to support developing locally with just `require_relative` and no Bundler.
  #
  # [0]: unless you manage to `bundle exec` at exactly 00:00:00 UTC :)
  GEM_PACKAGE_TIME = proc { begin; ::Gem::Specification::find_by_name(-'checking-you-out').date; rescue ::Gem::LoadError; ::Time.now; end }


  # Demote any CYO to a CYI that can be passed around in just 40 bytes.
  # CYI has the opposites of these methods.
  def out; self; end
  def in; self.class.superclass.new(*self.values); end

  # Add a new filename-match to a specific type.
  def add_pathname_fragment(fragment)
    # Store single-extname "postfix" matches separately from more complex matches
    # so we can list out file extensions easily.
    self.awen(fragment.postfix? ? :@postfixes : :@complexes, fragment)
  end
  attr_reader(:postfixes, :complexes)

  # Returns the "primary" file extension for this type.
  # For now we'll assume the `#first` extname is the primary.
  def extname
    case @postfixes
    when ::NilClass then nil
    when ::Symbol then @postfixes.to_s
    when ::String then @postfixes
    when ::Set then @postfixes.first
    else nil
    end&.delete_prefix(-?*)
  end

  # Unset the IVars for Postfixes and Complexes.
  def clear_pathname_fragments
    self.remove_instance_variable(:@postfixes)
    self.remove_instance_variable(:@complexes)
  end


  # Get a `Set` of this CYO and all of its parent CYOs, at minimum just `Set[self]`.
  def aka
    return case @aka
      when nil then ::Set[self.in]
      when self.class, self.class.superclass then ::Set[self.in, @aka]
      when ::Set then ::Set[self.in, *@aka]
    end
  end

  # Take an additional CYI as an alias for this CYO.
  def add_aka(taxa); self.awen(:@aka, taxa); end


  # CYO-to-CYI relationship mappings.
  attr_reader(:parents, :children)

  # Take an additional CYI as our parent, e.g. `application/xml` for an XML-based type.
  def add_parent(parent_cyi)
    self.awen(:@parents, parent_cyi)
  end

  # Take an additional CYI as our child type.
  def add_child(child_cyi)
    self.awen(:@children, child_cyi)
  end

  # Get a `Set` of this CYO and all of its parent CYOs, at minimum just `Set[self]`.
  def adults_table
    return case @parents
      when nil then ::Set[self]
      when self.class, self.class.superclass then ::Set[self, @parents]
      when ::Set then ::Set[self, *@parents]
    end
  end

  # Get a `Set` of this CYO and all of its child CYOs, at minimum just `Set[self]`.
  def kids_table
    return case @children
      when nil then ::Set[self]
      when self.class, self.class.superclass then ::Set[self, @children]
      when ::Set then ::Set[self, *@children]
    end
  end

  # Get a `Set` of this CYO and all parents and children, at minimum just `Set[self]`.
  def family_tree; self.kids_table | self.adults_table; end

  # Storage for freeform type descriptions (`<comment>` elements), type acrnyms,
  # suitable iconography, and other boring metadata, e.g.:
  #
  #   <mime-type type="application/vnd.oasis.opendocument.text">
  #     <comment>ODT document</comment>
  #     <acronym>ODT</acronym>
  #     <expanded-acronym>OpenDocument Text</expanded-acronym>
  #     <generic-icon name="x-office-document"/>
  #     […]
  #   </mini-type>
  attr_accessor(:description)


  # Avoid allocating spurious containers for keys that will only contain one value.
  # Given a key-name and a value, set the value for the key iff unset, otherwise promote the key
  # to a `Set` containing the previous plus the new values.
  def awen(haystack, needle)
    case self.instance_variable_get(haystack)
    when ::NilClass then
      self.instance_variable_set(haystack, needle)
    when ::Set then
      self.instance_variable_get(haystack).add(needle)
    else
      self.instance_variable_set(haystack, ::Set[self.instance_variable_get(haystack), needle])
    end
  end
  private(:awen)

end

# IETF Media-Type parser and methods that use that parser.
require_relative(-'auslandsgesprach') unless defined?(::CHECKING::YOU::IN::AUSLANDSGESPRÄCH)
::CHECKING::YOU::IN.extend(::CHECKING::YOU::IN::AUSLANDSGESPRÄCH)
::CHECKING::YOU::IN.include(::CHECKING::YOU::IN::INLANDGESPRÄCH)
::CHECKING::YOU::OUT.extend(::CHECKING::YOU::OUT::AUSLANDSGESPRÄCH)

# Content matching à la `libmagic`/`file`.
require_relative(-'sweet_sweet_love_magic') unless defined?(::CHECKING::YOU::OUT::SweetSweet♥Magic)
::CHECKING::YOU::OUT.extend(::CHECKING::YOU::OUT::SweetSweet♡Magic)
::CHECKING::YOU::OUT.prepend(::CHECKING::YOU::OUT::SweetSweet♥Magic)

# Methods for loading type data from `shared-mime-info` package XML files.
require_relative(-'ghost_revival') unless defined?(::CHECKING::YOU::GHOST_REVIVAL)
::CHECKING::YOU::IN.singleton_class.prepend(::CHECKING::YOU::IN::GHOST_REVIVAL)
::CHECKING::YOU::OUT.singleton_class.prepend(::CHECKING::YOU::OUT::GHOST_REVIVAL)
