# Components for working with POSIX `::String` globs, usually used for matching filenames.
#
# Glob stands for "global" according to Dennis Ritchie's `glob(7)` manual page from first-edition Research Unix:
# https://en.wikipedia.org/wiki/Research_Unix#Versions
# https://web.archive.org/web/20000829224359/http://cm.bell-labs.com/cm/cs/who/dmr/man71.pdf#page=10
#
#
# The modern standard is maintained as part of POSIX:
# https://pubs.opengroup.org/onlinepubs/9699919799/functions/glob.html sez: "The glob() function is a
#   pathname generator that shall implement the rules defined in XCU `Pattern Matching Notation`[0],
#   with optional support for rule 3 in XCU `Patterns Used for Filename Expansion`[1]."
#
# [0]: https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_13
# [1]: https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_13_03
#
# Per [0], "The pattern matching notation described in this section is used to specify patterns
#   for matching strings in the shell. Historically, pattern matching notation is related to,
#   but slightly different from, the regular expression notation described in XBD Regular Expressions.
#   For this reason, the description of the rules for this pattern matching notation are based on
#   the description of regular expression notation, modified to account for the differences."
#
#
# The modern Lunix `glob(7)` manpage offers a generally-more-concise description of the rules
# and is what will usually be quoted in my mid-code comments:
# https://man7.org/linux/man-pages/man7/glob.7.html
#
#
# Python has this in its standard library as `fnmatch.translate`:
# https://docs.python.org/3/library/fnmatch.html#fnmatch.translate
# https://github.com/python/cpython/blob/main/Lib/fnmatch.py
# https://github.com/python/cpython/blob/main/Lib/test/test_fnmatch.py
#
#
# TODO: A Refinement for `::String` for the implicit instance-level `to_regexp`:
# https://ruby-doc.org/core/Regexp.html#method-c-try_convert
class ::XROSS; end
class ::XROSS::THE; end
class ::XROSS::THE::POSIX; end
class ::XROSS::THE::POSIX::Glob
  def self.to_regexp(otra, flags = 0)
    return unless otra.is_a?(::String)
    return if otra.empty?

    # We can't initialize a `::Regexp` and add to its pattern as we go,
    # but we can construct a `::String` pattern that way and then feed it to `::Regexp::new`.
    subpatterns = ::Array::new.push(::Array::new)

    # Work with codepoints to avoid allocation of the single-character `::String`s in `#each_char`.
    otra.each_codepoint.with_index { |codepoint, index|
      case codepoint
      when ?*.ord then
        # "A '*' (not between brackets) matches any string, including the empty string."
        # An asterisk must not be the first character of a `::Regexp` pattern
        # or we will get a "target of repeat operator is not specified" `::SyntaxError`.
        subpatterns.last.push(?..ord) unless (
          [?*.ord, ?+.ord].include?(subpatterns.last.last)
        ) or (
          subpatterns.last.last.eql?(?\\.ord) and not subpatterns.last[-2]&.eql?(?\\.ord)
        )
        # Condense multiple-asterisk Globs into a single `.*`.
        subpatterns.last.push(codepoint) unless [?*.ord, ?+.ord].include?(subpatterns.last.last)
      when ??.ord then
        # "A '?' (not between brackets) matches any single character."
        # A `::Regexp` pattern uses a single '.' as the equivalent,
        # but we should match the explicit '?' if we're inside a bracket subpattern or if it's escaped.
        subpatterns.last.push(
          (subpatterns.last.first.eql?(?[.ord) or subpatterns.last.last.eql?(?\\.ord)) ? codepoint : ?..ord
        )
      when ?..ord then
        # A single '.' in a `::Regexp` pattern has the same meaning as the unbracketed single '?' glob,
        # matching any single character, so a '.' Glob character must be escaped to be matched explicitly.
        subpatterns.last.push(?\\.ord, codepoint)
      when ?\\.ord then
        subpatterns.last.push(codepoint)
      when ?[.ord then
        # "An expression '[...]' where the first character after the leading '[' is not an '!'
        #  matches a single character, namely any of the characters enclosed by the brackets."
        # We will start a new subpattern for this so we can easily find and escape it if unclosed.
        if subpatterns.last.last.eql?(?\\.ord) and not subpatterns.last[-2]&.eql?(?\\.ord) then
          subpatterns.last.push(codepoint)
        else
          subpatterns.push(::Array::new.push(codepoint))
        end
      when ?].ord then
        if subpatterns.last.first.eql?(?[.ord) then
          # "The string enclosed by the brackets cannot be empty; therefore ']' can be allowed between the brackets,
          #  provided that it is the first character.  (Thus, '[][!]' matches the three characters '[', ']', and '!'.)"
          # This means we must escape any ']' character that is the second character of a bracket subpattern.
          subpatterns.last.push(?\\.ord) if subpatterns.last.size.eql?(1) or (
            # If we are in a character class and the last character was the escape sequence,
            # we must double-escape to match that sequence explicitly instead of letting it escape the close bracket.
            subpatterns.last.last.eql?(?\\.ord) and not subpatterns.last[-2]&.eql?(?\\.ord)
          )
          subpatterns.last.push(codepoint)
          # If a closing-bracket balances our last subpattern, roll that subpattern into the subpattern before it.
          subpatterns.pop.yield_self { subpatterns.last.push(*_1) } if subpatterns.last.first.eql?(?[.ord) and subpatterns.size > 1
        else
          # If we're not in a character class, we must still check for an escape sequence to avoid
          # `warning: regular expression has ']' without escape`.
          subpatterns.last.push(?\\.ord) unless subpatterns.last.last.eql?(?\\.ord) and not subpatterns.last[-2]&.eql?(?\\.ord)
          subpatterns.last.push(codepoint)
        end
      when ?!.ord then
        # "An expression '[!...]' matches a single character, namely any character that is not matched by
        #  the expression obtained by removing the first '!' from it.
        #  (Thus, '[!]a-]' matches any single character except ']', 'a', and '-'.)"
        # A `::Regexp` pattern uses '[^...]' for bracket negation,
        # so only add '!' explicitly if we are not in a bracket subpattern.
        subpatterns.last.push(
          (subpatterns.last.first.eql?(?[.ord) and subpatterns.last.size.eql?(1)) ? ?^.ord : codepoint
        )
      when ?^.ord then
        # '^' is the beginning-of-line Anchor and the Character-class negation operator in a `::Regexp` pattern,
        # so we must escape it to match it explicitly.
        #
        # NOTE: Even though it's nonstandard we should treat a '^' which begins a Glob pattern character class
        #       as negation just like in a `::Regexp` pattern. Per Lunix's `glob(7)` manpage:
        #
        #       "Now that regular expressions have bracket expressions where the negation is indicated by a '^',
        #        POSIX has declared the effect of a wildcard pattern '[^...]' to be undefined."
        #
        #       This is the same behavior as Ruby's `::File::fnmatch`:
        #         irb> ::File::fnmatch("[a]", "a") => true
        #         irb> ::File::fnmatch("[^a]", "a") => false
        #         irb> ::File::fnmatch("[!a]", "a") => false
        subpatterns.last.push(?\\.ord) unless subpatterns.last.first.eql?(?[.ord) and subpatterns.last.size.eql?(1)
        subpatterns.last.push(codepoint)
      # when (?{.ord and not (flags & ::File::FNM_EXTGLOB).zero?) then  TODO
      when ?0.ord then
        # `glob(7)` patterns can't contain nulls, so we should emulate that behavior
        # even though a `::Regexp` pattern supports it just fine:
        #   irb> /lol\0rofl/ == 'hello.jpg' => false
        #   irb> ::File::fnmatch("lol\0lmao", "hello.jpg")
        #   (irb):in `fnmatch': string contains null byte (ArgumentError)
        raise(::ArgumentError, 'string contains null byte') if (
          subpatterns.last.last.eql?(?\\.ord) and not subpatterns.last.first.eql?(?\\.ord)
        )
      else
        # Remove spurious Glob-inherited escape sequences unless we're in a character class.
        subpatterns.last.pop if subpatterns.last.last.eql?(?\\.ord) and not subpatterns.last.first.eql?(?[.ord)
        subpatterns.last.push(codepoint)
      end
    }

    # Escape any unpaired brackets/braces in our subpatterns.
    # Any opening bracket/brace character starts a new subpattern, and any matching
    # closing bracket/brace collapses the `#last` subpattern into the one before it.
    # This means any subpattern we see still beginning with a bracket/brace is unpaired.
    subpatterns.each.with_index {
      _1.unshift(?\\.ord) if _1.first.eql?(?[.ord) and not _2.eql?(0)
      # TODO: Braces.
    }

    # Add an explicit beginning/end-of-`::String` Anchor to our pattern:
    # https://ruby-doc.org/core/Regexp.html#class-Regexp-label-Anchors
    subpatterns.last.push(?\\.ord).push(?Z.ord).tap {
      _1.unshift(?A.ord)
      _1.unshift(?\\.ord)
    }

    # TODO: Fix exponential denial-of-service vulnerability from patterns with repeating expansions,
    # just like with Python's `fnmatch.translate`: https://bugs.python.org/issue40480
    # TODO: Support the other Faith No More flags like `::File::FNM_PATHNAME`.

    ::Regexp::new(subpatterns.flatten.pack('U*'))
  end
end
