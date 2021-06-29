require 'set' unless defined? ::Set
require 'pathname' unless defined? ::Pathname


# Utility Modules/procs/lambdas/etc for generic operations like checking WeightedActions.
require_relative 'party_starter' unless defined? ::CHECKING::YOU::WeightedAction


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
CHECKING::YOU::IN ||= Struct.new(
  # Intentionally avoiding naming taxonomic ranks like "domain", "class", or "order"
  # whose names are already common in computing.
  :kingdom,
  :phylum,
  :genus,
) do
  # Promote any CYI to its CYO singleton. CYO has the opposites of these methods.
  def out; ::CHECKING::YOU::OUT::new(self); end
  def in; self; end
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
  GEM_ROOT = proc { File.expand_path(File.join(__dir__, *Array.new(2, '..'.freeze))) }

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
  GEM_PACKAGE_TIME = proc { begin; Gem::Specification::find_by_name(-'checking-you-out').date; rescue Gem::LoadError; Time.now; end }

  Species = Struct.new(:name, :value) do
    def self.from_string(param_string)
      return self.new(*param_string.split(-?=))
    end
  end

  # Main memoization Hash for our loaded Type data.
  # { CHECKING::YOU::IN => CHECKING::YOU::OUT }
  def self.all_night; @all_night ||= Hash.new(nil); end

  # Return a singleton instance for any CYO.
  def self.new(taxa)
    # Support IETF String argument to this method, e.g. ::CHECKING::YOU::OUT::new('application/octet-stream')
    return self.from_ietf_media_type(taxa) if taxa.is_a?(String)
    # Otherwise return the memoized CYO singleton of this type.
    self.all_night[
      taxa.is_a?(::CHECKING::YOU::IN) ? taxa : super(*taxa)
    ] ||= self.allocate.tap { |cyo| cyo.send(:initialize, *taxa) }
  end

  # Demote any CYO to a CYI that can be passed around in just 40 bytes.
  # CYI has the opposites of these methods.
  def out; self; end
  def in; self.class.all_night.key(self); end


  # Get a CYO, Set[CYO], or nil by file-extension, e.g. `doc` => { CYO msword, CYO rtf }
  def self.from_postfix(postfix)
    # `:extname` will return the last dotted component with the leading dot, e.g. `File::extname("hello.jpg")` => `".jpg"`.
    # `:extname` will be an empty String for paths which contain no dotted components.
    self.instance_variable_get(:@after_forever)[case postfix
      when Postfix    then postfix
      when ::Symbol   then postfix.to_s  # TODO: Ruby 3.0 Symbol#name
      when ::Pathname then postfix.extname.delete_prefix!(-?.) || postfix.to_s
      when ::String   then postfix.delete_prefix(-?.) || postfix.to_s
      else postfix.to_s
    end]
  end

  # Get a Hash[CYO] or nil for arbitrary non-file-extension glob match of a File basename.
  def self.from_glob(basename)
    self.instance_variable_get(:@stick_around).select { |k,v|
      File.fnmatch?(k, basename, File::FNM_CASEFOLD | File::FNM_DOTMATCH)
    }.yield_self { |matched|
      matched.empty? ? nil : matched
    }
  end

  # We will decompose `shared-mime-info`'s `<glob>` elements into two WeightedActions.
  # The vast majority of `<glob>`s are of the form `*.extname`, and storing them separately
  # not only accelerates lookup by extension but allows CYOs to easily suggest extnames
  # for themselves à la `ruby-mime-types`'s `MIME::Type#preferred_extension`.
  # These will be stripped of their leading '*.' and stored as just the extname.
  class Postfix < ::String; include ::CHECKING::YOU::WeightedAction; end
  # All other globs will be stored freeform, e.g. `Makefile.*`.
  class Glob    < ::String; include ::CHECKING::YOU::WeightedAction; end


  # Add a new Postfix or Glob for a specific type.
  def add_pathname_fragment(fragment)
    case fragment
    when Postfix then
      ::CHECKING::YOU::INSTANCE_NEEDLEMAKER.call(:@postfixes, fragment, self)
      ::CHECKING::YOU::CLASS_NEEDLEMAKER.call(:@after_forever, fragment, self)
    when Glob then
      ::CHECKING::YOU::INSTANCE_NEEDLEMAKER.call(:@globs, fragment, self)
      ::CHECKING::YOU::CLASS_NEEDLEMAKER.call(:@stick_around, fragment, self)
    end
  end

  # Search for Types matching an arbitrary Pathname.
  def self.from_pathname(pathname)
    pathname = Pathname.new(pathname) if pathname.is_a?(::String)
    # TODO: Implement `case-sensitive` flag.

    return case self.from_postfix(pathname)
    when self  then self.from_postfix(pathname)
    when ::Set then self.from_postfix(pathname)
    when nil   then self.from_glob(pathname.basename)
    end
  end

  attr_reader :aka

  # Take an additional CYI, store it locally, and memoize it as an alias for this CYO.
  def add_aka(taxa)
    taxa = taxa.is_a?(::CHECKING::YOU::IN) ? taxa : self.class.superclass.new(*taxa)
    ::CHECKING::YOU::INSTANCE_NEEDLEMAKER.call(:@aka, taxa, self)
    self.class.all_night[taxa] = self
  end

  # Forget a CYI alias of this Type. Capable of unsetting the "real" CYI as well if desired.
  def remove_aka(taxa)
    taxa = taxa.is_a?(::CHECKING::YOU::IN) ? taxa : self.class.superclass.new(*taxa)
    self.class.all_night.delete(taxa) if self.class.all_night.fetch(taxa, nil) === self
  end
  end

  # Storage for descriptions (`<comment>`), acrnyms, suitable iconography, and other boring metadata, e.g.:
  #   <mime-type type="application/vnd.oasis.opendocument.text">
  #     <comment>ODT document</comment>
  #     <acronym>ODT</acronym>
  #     <expanded-acronym>OpenDocument Text</expanded-acronym>
  #     <generic-icon name="x-office-document"/>
  #     […]
  #   </mini-type>
  attr_accessor :description

end

# IETF Media-Type parser and methods that use that parser.
require_relative 'auslandsgesprach' unless defined? ::CHECKING::YOU::IN::AUSLANDSGESPRÄCH
::CHECKING::YOU::IN.extend(::CHECKING::YOU::IN::AUSLANDSGESPRÄCH)
::CHECKING::YOU::IN.include(::CHECKING::YOU::IN::INLANDSGESPRÄCH)
::CHECKING::YOU::OUT.extend(::CHECKING::YOU::OUT::AUSLANDSGESPRÄCH)

# Content matching à la `libmagic`/`file`.
require_relative 'sweet_sweet_love_magic' unless defined? ::CHECKING::YOU::SweetSweet♥Magic
::CHECKING::YOU::OUT.extend(::CHECKING::YOU::SweetSweet♡Magic)
::CHECKING::YOU::OUT.prepend(::CHECKING::YOU::SweetSweet♥Magic)

# Methods for loading type data from `shared-mime-info` package XML files.
require_relative 'ghost_revival' unless defined? ::CHECKING::YOU::GHOST_REVIVAL
::CHECKING::YOU::OUT.extend(::CHECKING::YOU::OUT::GHOST_REVIVAL)
