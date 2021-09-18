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

  # Message `::Struct` for inter-`::Ractor` communication. These will be sent with `move: true`
  # and will be mutable. The receiver `::Ractor` will take the `:request`, mutate the message
  # to contain the resulting `:response`, and send the mutated message to the `:destination`.
  #
  # TODO: Re-evaluate this in Ruby 3.1+ depending on the outcome of https://bugs.ruby-lang.org/issues/17298
  self::EverlastingMessage = ::Struct.new(:destination, :request, :response) do
    # Hash the entire message based on the `#hash` of its `:request` member.
    # The resulting `::Integer` will be used in the cache `::Hash`/`::Set` because the message
    # object itself will become a `::Ractor::MovedObject` after it's sent to `:destination`.
    def hash; self[:request].hash; end
  end

  # Symbolize our `::Struct` values if they're given separately (not as a CYI/CYO).
  def initialize(*taxa)
    super(*(taxa.first.is_a?(::CHECKING::YOU::IN) ? taxa.first : taxa.map!(&:to_sym)))
  end

  # Promote any CYI to its CYO singleton. CYO has the opposites of these methods.
  def out(area_code: self.class::DEFAULT_AREA_CODE)
    ::CHECKING::YOU::OUT[self, area_code: area_code]
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
  # After ${negative-UTC-offset} hours before midnight localtime, this will give you a *day* that seems to be in the future
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

# File-extension handling and filename matching for basic (e.g. `"*.jpg"`) and complex globs.
require_relative(-'stella_sinistra') unless defined?(::CHECKING::YOU::OUT::StellaSinistra)
::CHECKING::YOU::OUT.include(::CHECKING::YOU::OUT::StellaSinistra)

# CYO-to-CYO relationship management.
require_relative(-'moon_child') unless defined?(::CHECKING::YOU::OUT::MOON_CHILD)
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
