require(-'set') unless defined?(::Set)
require(-'pathname') unless defined?(::Pathname)
require(-'securerandom') unless defined?(::SecureRandom)


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

  # This `::Array` subclass will represent the sum of `CYI`s for a `CYO` whose IETF media-type `::String`
  # uses a "suffix" designated by `+` or `;`, e.g. `image/svg+xml` will be `B4U[ CYI(svg), CYI(xml) ]`.
  self::B4U = ::Class::new(::Set)

  # Default `::Ractor` CYO data area name.
  # This will be the area used for all synchronous method invocations that do not specify otherwise.
  self::DEFAULT_AREA_CODE = :CYO

  # Message `::Struct` for inter-`::Ractor` communication. These will be sent with `move: true`
  # and will be mutable. The receiver `::Ractor` will take the `:request`, mutate the message
  # to contain the resulting `:response`, and send the mutated message to the `:destination`.
  #
  # TODO: Re-evaluate this in Ruby 3.1+ depending on the outcome of https://bugs.ruby-lang.org/issues/17298
  self::EverlastingMessage = ::Struct.new(:erosion_mark, :in_motion, :chain_of_pain) do
    def initialize(in_motion, chain_of_pain = ::Ractor::current)
      super(::SecureRandom::uuid.freeze, in_motion, chain_of_pain)
    end
    def add_destination(otra)
      case self[:chain_of_pain]
      when ::Ractor then self[:chain_of_pain] = ::Array[self[:chain_of_pain], otra]
      when ::Array then self[:chain_of_pain].push(otra)
      end
    end
    def go_beyond!
      case self[:chain_of_pain]
      when ::Ractor then self[:chain_of_pain].send(self, move: true)
      when ::Array then
        dest = self[:chain_of_pain].last
        self[:chain_of_pain] = ::Ractor::make_shareable((self[:chain_of_pain])[...-1])
        dest.send(self, move: true)
      end
    end
  end

  # Symbolize our `::Struct` values if they're given separately (not as a CYI/CYO).
  def initialize(*taxa)
    return if taxa.nil? or taxa.include?(nil)
    super(*(taxa.first.is_a?(::CHECKING::YOU::IN) ? taxa.first : taxa.map!(&:to_sym)))
  end

  # Promote any CYI to its CYO singleton. CYO has the opposites of these methods.
  def out(area_code: self.class::DEFAULT_AREA_CODE)
    ::CHECKING::YOU::OUT[self, area_code: area_code]
  end
  def in; self; end

  # *Disable* decomposition of a CYI/CYO into its component values.
  # It can still be done by decomposing `#values`, but this will allow us to "splat"
  # without worrying if we are splatting a single CYI/CYO or a `::Set` of them.
  #
  # Before: `irb> [*(CYI::from_ietf_media_type('image/jpeg'))] => [:possum, :image, :jpeg]`
  #
  # After, with `#to_a = nil`:
  # `irb> [*(CYI::from_ietf_media_type('image/jpeg'))]
  #   => [#<struct CHECKING::YOU::IN kingdom=:possum, phylum=:image, genus=:jpeg>]`
  def to_a; nil; end

  # e.g. irb> CYI::from_ietf_media_type('image/jpeg') == 'image/jpeg' => true
  def eql?(otra)
    case otra
    when ::String then self.to_s.eql?(otra.index(/[;+]/) ? otra.slice(...otra.index(/[;+]/)) : otra)
    when ::CHECKING::YOU::IN, ::CHECKING::YOU::OUT then self.values.eql?(otra.values)
    else super(otra)
    end
  end
  alias_method(:==, :eql?)
end

# Main Struct subclass for in-memory type representation.
class ::CHECKING::YOU::OUT < ::CHECKING::YOU::IN

  # HACK: Sending a `CYO::EM` to the IETF Media Type parser will cause it to instantiate
  #       a `{CYI => CYO}` reply instead of a plain `CYI`.
  self::EverlastingMessage = ::Class::new(self::superclass::EverlastingMessage)

  # Absolute path to the root of the Gem — the directory containing `bin`,`docs`,`lib`, etc.
  self::GEM_ROOT = ::Ractor::make_shareable(
    proc { ::Pathname.new(__dir__).join(*::Array.new(2, -'..')).expand_path.realpath }
  )

  # Time object representing the day this running CYO Gem was packaged.
  #
  # `Gem::Specification#date` can be slightly misleading when developing locally with Bundler using `bundle exec`.
  # One might expect the result of `#date` to be "now" (including hours/minutes/seconds) in UTC for such a runtime-packaged Gem,
  # but it will always be midnight UTC of the current day (also in UTC), i.e. a date that is always[0] in the past.
  #
  # After ${negative-UTC-offset} hours before midnight localtime, this will give you a *day* that seems to be in the future
  # compared to a system clock displaying localtime despite that *date* UTC still being in the past,
  # e.g. as I write this comment at 2021-05-25 22:22 PST, `GEM_PACKAGE_TIME.call` returns `2021-05-26 00:00:00 UTC`.
  #
  # Rescue from `Gem::MissingSpecError`'s parent to support developing locally with just `require_relative` and no Bundler.
  #
  # [0]: unless you manage to `bundle exec` at exactly 00:00:00 UTC :)
  #
  # NOTE: For now this has to be computed on the main `::Ractor` since `::Gem::Requirement::DefaultRequirement` is not shareable.
  self::GEM_PACKAGE_TIME = ::Ractor::make_shareable(
    begin; ::Gem::Specification::find_by_name(-'checking-you-out').date.to_i; rescue ::Gem::LoadError; ::Time.now.to_i; end
  )


  # Demote any CYO to a CYI that can be passed around in just 40 bytes.
  # CYI has the opposites of these methods.
  def out; self; end
  def in
    # In most cases we can return a single new CYI reusing the values from our own self,
    # but certain child types and types-with-`Species` need a combination CYI.
    # TODO: Species support.
    case self.b4u
    when ::CHECKING::YOU::IN then Set[self.class.superclass.new(*self.values), self.b4u]
    when ::CHECKING::YOU::IN::B4U, ::Set then ::Set[self.class.superclass.new(*self.values)].merge(self.b4u)
    else self.class.superclass.new(*self.values)
    end
  end

  def eql?(otra)
    case otra
    when ::String             then self.to_s.eql?(otra)
    when ::CHECKING::YOU::IN  then self.values.eql?(otra.values)
    when ::CHECKING::YOU::OUT then
      self.values.eql?(otra.values) and self.parents.eql?(otra.parents)  # TODO: and self.species.eql?(self.species)
    else super(otra)
    end
  end
  alias_method(:==, :eql?)

  # Avoid allocating spurious containers for keys that will only contain one value.
  # Given a key-name and a value, set the value for the key iff unset, otherwise promote the key
  # to a `Set` containing the previous plus the new values.
  def awen(haystack, needle)
    case self.instance_variable_get(haystack)
    when ::NilClass then self.instance_variable_set(haystack, needle)
    when ::Set      then self.instance_variable_get(haystack).add(needle)
    when needle     then # No-op.
    else self.instance_variable_set(haystack, ::Set[self.instance_variable_get(haystack), needle])
    end
  end
  private(:awen)

end

# IETF Media-Type parser and methods that use that parser.
require_relative(-'auslandsgesprach') unless defined?(::CHECKING::YOU::IN::AUSLANDSGESPRÄCH)
::CHECKING::YOU::IN.extend(::CHECKING::YOU::IN::AUSLANDSGESPRÄCH)
::CHECKING::YOU::IN.include(::CHECKING::YOU::IN::INLANDGESPRÄCH)
::CHECKING::YOU::OUT.extend(::CHECKING::YOU::OUT::AUSLANDSGESPRÄCH)
::CHECKING::YOU::OUT.include(::CHECKING::YOU::OUT::INLANDGESPRÄCH)

# File-extension handling and filename matching for basic (e.g. `"*.jpg"`) and complex globs.
require_relative(-'stella_sinistra') unless defined?(::CHECKING::YOU::OUT::StellaSinistra)
::CHECKING::YOU::OUT.include(::CHECKING::YOU::OUT::StellaSinistra)

# CYO-to-CYO relationship management.
require_relative(-'moon_child') unless defined?(::CHECKING::YOU::OUT::MOON_CHILD)
::CHECKING::YOU::IN.include(::CHECKING::YOU::IN::MOON_CHILD)
::CHECKING::YOU::OUT.include(::CHECKING::YOU::OUT::MOON_CHILD)

# Static type information like plain-text descriptions and graphical icons.
require_relative(-'texture') unless defined?(::CHECKING::YOU::OUT::TEXTURE)
::CHECKING::YOU::OUT.include(::CHECKING::YOU::OUT::TEXTURE)

# Content matching à la `libmagic`/`file`.
require_relative(-'sweet_sweet_love_magic') unless defined?(::CHECKING::YOU::OUT::SweetSweet♥Magic)
::CHECKING::YOU::OUT.extend(::CHECKING::YOU::OUT::SweetSweet♡Magic)
::CHECKING::YOU::OUT.include(::CHECKING::YOU::OUT::SweetSweet♥Magic)

# Methods for loading type data from `shared-mime-info` package XML files.
require_relative(-'ghost_revival') unless defined?(::CHECKING::YOU::GHOST_REVIVAL)
::CHECKING::YOU::OUT.singleton_class.prepend(::CHECKING::YOU::OUT::GHOST_REVIVAL)
