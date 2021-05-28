require 'set' unless defined? Set


module CHECKING; end
class CHECKING::YOU; end


# Note:

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
  # This can be slightly misleading during development when it's not a packaged Gem version
  # since you'd expect the result of `#date` to be "now" in UTC, but it will be always midnight UTC
  # of the current day (also in UTC) regardless of the actual time in UTC on that day,
  # meaning it will give you a *`date`* that's in the past until ${your-UTC-offset} hours before midnight localtime,
  # at which time this will give you a *`day`* that seems to be in the future compared to a system clock displaying localtime,
  # e.g. as I write this comment at 2021-05-25 22:22 PST, `GEM_PACKAGE_TIME.call` returns `2021-05-26 00:00:00 UTC`.
  GEM_PACKAGE_TIME = proc { Gem::Specification::find_by_name('checking-you-out'.freeze).date }

  Species = Struct.new(:name, :value) do
    def self.from_string(param_string)
      return self.new(*param_string.split('='.freeze))
    end
  end

  # Main memoization Hash for our loaded Type data.
  # { CHECKING::YOU::IN => CHECKING::YOU::OUT }
  def self.remember_me
    @remember_me ||= Hash.new
  end

  def self.new(taxa)
    self.remember_me[
      taxa.is_a?(::CHECKING::YOU::IN) ? taxa : super(*taxa)
    ] ||= self.allocate.tap { |cyo| cyo.send(:initialize, *taxa) }
  end

  def out; self; end
  def in; self.class.remember_me.key(self); end

  # Memoization Hash for file extensions.
  # { Symbol => CHECKING::YOU::OUT }
  def self.after_forever
    @after_forever ||= Hash.new { |h,k| h[k] = Set.new }
  end

  # Get a Set[CYO] by Symbol file-extension, e.g. `:doc` => { CYO msword, CYO rtf }
  def self.from_postfix(postfix)
    self.after_forever[case postfix
      when Symbol then postfix
      when String then postfix.delete_prefix('.'.freeze).to_sym
      else postfix.to_sym
    end]
  end

  # Set of postfixes specific to one CYO object.
  def postfixes
    @postfixes ||= Set.new
  end

  # Add a new postfix for a specific type.
  def add_postfix(postfix)
    self.postfixes.add(postfix)
    self.class.after_forever[postfix].add(self)
  end

  # Get the type of a file at a given filesystem path.
  def self.from_pathname(pathname)
    # TOD0: Convert String args to Pathname here and in IETF's `from_pathname`

    # The `File` module will take either `String` or `Pathname`, so just use it instead of detecting input Class.
    #
    # `File::extname` will return the last dotted component with the leading dot,
    # e.g. `File::extname("hello.jpg")` => `".jpg"`.
    # Remove it here before looking up CYO objects by extension.
    #
    # `File::extname` will be an empty String for paths which contain no dotted components.
    super || self.from_postfix(File.extname(pathname).delete_prefix!('.'.freeze))
  end

  def aka
    @aka ||= Set.new
  end

  def add_aka(taxa)
    cyi = taxa.is_a?(::CHECKING::YOU::IN) ? taxa : self.class.superclass.new(*taxa)
    self.aka.add(cyi)
    self.class.remember_me[cyi] = self
  end

  def remove_aka(taxa)
    cyi = taxa.is_a?(::CHECKING::YOU::IN) ? taxa : self.class.superclass.new(*taxa)
    self.class.remember_me.delete(cyi) if self.class.remember_me.fetch(cyi, nil) === self
  end

  attr_accessor :description

end

# IETF Media-Type parser and methods that use that parser.
require_relative 'auslandsgesprach' unless defined? ::CHECKING::YOU::IN::AUSLANDSGESPRÄCH
::CHECKING::YOU::IN.extend(::CHECKING::YOU::IN::AUSLANDSGESPRÄCH)
::CHECKING::YOU::IN.include(::CHECKING::YOU::IN::INLANDSGESPRÄCH)
::CHECKING::YOU::OUT.extend(::CHECKING::YOU::OUT::AUSLANDSGESPRÄCH)

# Methods for loading type data from `shared-mime-info` package XML files.
require_relative 'ghost_revival' unless defined? ::CHECKING::YOU::GHOST_REVIVAL
::CHECKING::YOU::OUT.extend(::CHECKING::YOU::OUT::GHOST_REVIVAL)
