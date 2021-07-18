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


  # Get a CYO, Set[CYO], or nil by file-extension, e.g. `doc` => { CYO msword, CYO rtf }.
  POSTFIX_KEY = proc {
    # Re-use a single search structure to avoid allocating an Object per search.
    scratch = ::CHECKING::YOU::StickAround.new(-'')
    # Additionally accelerate multiple searches for the same thing by avoiding `StickAround#replace`
    # if the new search key already matches the previous search key.
    # Mark `case_sensitive: false` here for testing arbitrarily-named input.
    -> { scratch.eql?(_1) ? scratch : scratch.replace(_1, case_sensitive: false) }
  }.call
  def self.from_postfix(stick_around)
    self.instance_variable_get(:@after_forever)[POSTFIX_KEY.call(stick_around)]
  end

  # Get a Hash[CYO] or nil for arbitrary non-file-extension glob match of a File basename.
  def self.from_glob(stick_around)
    self.instance_variable_get(:@stick_around).select { |k,v|
      k.eql?(stick_around)
    }.yield_self { |matched|
      matched.empty? ? nil : matched
    }
  end

  def self.from_pathname(pathname)
    return self.from_glob(pathname) || self.from_postfix(pathname)
  end


  # Add a new Postfix or Glob for a specific type.
  def add_pathname_fragment(fragment)
    if fragment.start_with?(-'*.') and fragment.count(-?.) == 1 and fragment.count(-?*) == 1 then
      ::CHECKING::YOU::INSTANCE_NEEDLEMAKER.call(:@postfixes, fragment, self)
      ::CHECKING::YOU::CLASS_NEEDLEMAKER.call(:@after_forever, fragment, self)
    else
      ::CHECKING::YOU::INSTANCE_NEEDLEMAKER.call(:@globs, fragment, self)
      ::CHECKING::YOU::CLASS_NEEDLEMAKER.call(:@stick_around, fragment, self)
    end
  end


  # Get a `Set` of this CYO and all of its parent CYOs, at minimum just `Set[self]`.
  def aka
    return case @aka
      when nil then Set[self.in]
      when self.class, self.class.superclass then Set[self.in, @aka]
      when ::Set then Set[self.in, *@aka]
    end
  end

  # Take an additional CYI, store it locally, and memoize it as an alias for this CYO.
  def add_aka(taxa)
    taxa = taxa.is_a?(::CHECKING::YOU::IN) ? taxa : self.class.superclass.new(*taxa)
    ::CHECKING::YOU::INSTANCE_NEEDLEMAKER.call(:@aka, taxa, self)
    self.class.all_night[taxa] = self
  end

  # Forget a CYI alias of this Type. Capable of unsetting the "real" CYI as well if desired.
  def remove_aka(taxa)
    taxa = taxa.is_a?(::CHECKING::YOU::IN) ? taxa : self.class.superclass.new(*taxa)
    self.class.all_night.delete(taxa) if self.class.all_night[taxa] === self
  end

  attr_reader :parents, :children

  # Take an additional CYO, store it locally as our parent, and ask it to add ourselves as its child.
  def add_parent(parent_cyo)
    ::CHECKING::YOU::INSTANCE_NEEDLEMAKER.call(:@parents, parent_cyo, self)
    parent_cyo.add_child(self) unless parent_cyo.children&.include?(self)
  end

  # Take an additional CYO, store it locally as our child, and ask it to add ourselves as its parent.
  def add_child(child_cyo)
    ::CHECKING::YOU::INSTANCE_NEEDLEMAKER.call(:@children, child_cyo, self)
    child_cyo.add_parent(self) unless child_cyo.parents&.include?(self)
  end

  # Get a `Set` of this CYO and all of its parent CYOs, at minimum just `Set[self]`.
  def adults_table
    return case @parents
      when nil then Set[self]
      when self.class, self.class.superclass then Set[self, @parents]
      when ::Set then Set[self, *@parents]
    end
  end

  # Get a `Set` of this CYO and all of its child CYOs, at minimum just `Set[self]`.
  def kids_table
    return case @children
      when nil then Set[self]
      when self.class, self.class.superclass then Set[self, @children]
      when ::Set then Set[self, *@children]
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
