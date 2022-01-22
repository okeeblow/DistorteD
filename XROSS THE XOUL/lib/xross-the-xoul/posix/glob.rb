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

    # "Wildcard" Glob pattern sequences (like the single-character '?' and multi-character '*')
    # do not match path separators unless the `::File::FNM_PATHNAME` flag is enabled,
    # i.e. they will respectively match `/[^\/]/` or `/[^\/]*/` assuming `::File::SEPARATOR` is `/`.
    #
    # We must also match any `::File::ALT_SEPARATOR` if one is enabled. This constant is usually just `nil`
    # on Unix-like systems, but it will be the `\` (backslash) separator on Winders.
    #
    # I'm going to go ahead and define this once here since we are likely to need it multiple times,
    # including checking if the `#last` subpattern is a wildcard, and it would be gross to define it
    # multiple times inline.
    negate_separator = [
      ?[,
      ?^,
      # The regular `::File::SEPARATOR` will usually be a forward-slash which needs to be escaped in a `::Regexp,
      # but passing the computed pattern `::String` to `::Regexp::new` will do the escaping for us.
      # AFAIK there's no platform where `::File::SEPARATOR` will be `\`, but support escaping one anyway just in case.
      (::File::SEPARATOR.eql?(?\\) ? ?\\ : nil),
      ::File::SEPARATOR,
      # `::File::ALT_SEPARATOR` will almost certainly be either `nil` or `\`, and if it is `\` it needs
      # to be escaped with another backslash, but don't just assume a non-`nil` `ALT_SEPARATOR` is `\`
      # since other platforms have different standards, e.g. Classic Macintoshes with the `:` separator.
      (::File::ALT_SEPARATOR.eql?(?\\) ? ?\\ : nil),
      ::File::ALT_SEPARATOR,
      ?],
    ].compact.map!(&:ord)  # Remove the likely `nil`s from disabled `ALT_SEPARATOR`.

    # Work with codepoints to avoid allocation of the single-character `::String`s in `#each_char`.
    otra.each_codepoint.with_index { |codepoint, index|
      case codepoint
      when ?*.ord then
        # "A '*' (not between brackets) matches any string, including the empty string."
        # An asterisk must not be the first character of a `::Regexp` pattern
        # or we will get a "target of repeat operator is not specified" `::SyntaxError`.
        #
        # TODO: Fix exponential denial-of-service vulnerability from patterns with repeating fixed expansions,
        #       just like with Python's `fnmatch.translate`: https://bugs.python.org/issue40480
        if (subpatterns.last.first.eql?(?[.ord) or (
          subpatterns.last.last.eql?(?\\.ord) and not subpatterns.last[-2].eql?(?\\.ord)
        )) then
          subpatterns.last.push(?\\.ord) unless subpatterns.last.last.eql?(?\\.ord) and not subpatterns.last[-2].eql?(?\\.ord)
          # Condense multiple-asterisk Globs into a single `.*`.
          subpatterns.last.push(codepoint) unless [?*.ord, ?+.ord].include?(subpatterns.last.last)
        else
          if (flags & ::File::FNM_PATHNAME).zero? then
            subpatterns.push(negate_separator).push([?*.ord]).push(::Array::new) unless (
              # This is kinda hacky, but it's important to collapse multiple sequential asterisks in the Glob pattern
              # even without `FNM_PATHNAME` to avoid avoid creating gross exponential `::Regexp` patterns like:
              #   irb> ::XROSS::THE::POSIX::Glob::to_regexp('********')
              #        => /\A[^\/]*[^\/]*[^\/]*[^\/]*[^\/]*[^\/]*[^\/]*[^\/]*\Z/
              subpatterns.last.empty? and subpatterns[-2].eql?([?*.ord]) and subpatterns[-3].eql?(negate_separator)
            )
          else
            subpatterns.last.push(?..ord) unless [?*.ord, ?+.ord].include?(subpatterns.last.last)
            # Condense multiple-asterisk Globs into a single `.*`.
            subpatterns.last.push(codepoint) unless [?*.ord, ?+.ord].include?(subpatterns.last.last)
          end
        end
      when ??.ord then
        # "A '?' (not between brackets) matches any single character."
        # A `::Regexp` pattern uses a single '.' as the equivalent,
        # but we should match the explicit '?' if we're inside a bracket subpattern or if it's escaped.
        if (subpatterns.last.first.eql?(?[.ord) or (
          subpatterns.last.last.eql?(?\\.ord) and not subpatterns.last[-2].eql?(?\\.ord)
        )) then
          # Explicitly match a single `?` character since we are escaped.
          subpatterns.last.push(codepoint)
        else
          if (flags & ::File::FNM_PATHNAME).zero? then
            # Begin a new empty subpattern after appending the precomputed non-separator-matching wildcard.
            subpatterns.push(negate_separator).push(::Array::new)
          else
            # Match any single character *including* `::File::SEPARATOR`.
            subpatterns.last.push(?..ord)
          end
        end
      when ?..ord then
        # A single '.' in a `::Regexp` pattern has the same meaning as the unbracketed single '?' glob,
        # matching any single character, so a '.' Glob character must be escaped to be matched explicitly.
        subpatterns.last.push(?\\.ord, codepoint)
      when ?\\.ord then
        # If the `::File::FNM_NOESCAPE` flag is set, treat the '/' character as something to
        # explicitly match instead of treating it as an escape character.
        subpatterns.last.push(codepoint) unless (flags & ::File::FNM_NOESCAPE).zero?
        subpatterns.last.push(codepoint)
      when ?[.ord then
        # "An expression '[...]' where the first character after the leading '[' is not an '!'
        #  matches a single character, namely any of the characters enclosed by the brackets."
        # We will start a new subpattern for this so we can easily find and escape it if unclosed.
        if subpatterns.last.last.eql?(?\\.ord) and not subpatterns.last[-2].eql?(?\\.ord) then
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
            subpatterns.last.last.eql?(?\\.ord) and not subpatterns.last[-2].eql?(?\\.ord)
          )
          subpatterns.last.push(codepoint)
          # If a closing-bracket balances our last subpattern, roll that subpattern into the subpattern before it.
          subpatterns.pop.yield_self { subpatterns.last.push(*_1) } if subpatterns.last.first.eql?(?[.ord) and subpatterns.size > 1
        else
          # If we're not in a character class, we must still check for an escape sequence to avoid
          # `warning: regular expression has ']' without escape`.
          subpatterns.last.push(?\\.ord) unless subpatterns.last.last.eql?(?\\.ord) and not subpatterns.last[-2].eql?(?\\.ord)
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
        # https://www.ruby-lang.org/en/news/2019/10/01/nul-injection-file-fnmatch-cve-2019-15845/
        #
        # NOTE: Null (0) != ("0".ord == 48), but we're decomposing a `::String` here so this is expected.
        #       An actual actionable null will have been escaped first.
        if subpatterns.last.last.eql?(?\\.ord) then
          raise(::ArgumentError, 'string contains null byte')
        else
          subpatterns.last.push(codepoint)
        end
      else
        # Remove spurious Glob-inherited escape sequences unless we're in a character class
        # or have the `::File::FNM_NOESCAPE` flag set.
        subpatterns.last.pop if (
          subpatterns.last.last.eql?(?\\.ord) and (flags & ::File::FNM_NOESCAPE).zero?
        ) and not subpatterns.last.first.eql?(?[.ord)
        subpatterns.last.push(codepoint)
      end
    }

    # Escape any unpaired brackets/braces in our subpatterns.
    # Any opening bracket/brace character starts a new subpattern, and any matching
    # closing bracket/brace collapses the `#last` subpattern into the one before it.
    # This means any subpattern we see still beginning with a bracket/brace is unpaired.
    subpatterns.each.with_index {
      _1.unshift(?\\.ord) if _1.first.eql?(?[.ord) and not (_1.last.eql?(?].ord) or _2.eql?(0))
      # TODO: Braces.
    }

    # Exclude dotfiles by default unless the `::File::FNM_DOTMATCH` flag is set.
    # https://en.wikipedia.org/wiki/Hidden_file_and_hidden_directory#Unix_and_Unix-like_environments
    #
    # Use a lookahead for this so it doesn't affect the actual computed pattern, e.g.:
    #   irb> /\A.*\Z/         === '.profile' => true
    #   irb> /\A(?![\.]).*\Z/ === '.profile' => false
    #   irb> /\A(?![\.]).*\Z/ === 'profile'  => true
    subpatterns.unshift(*[?(, ??, ?!, ?[, ?\\, ?., ?], ?)].map!(&:ord)) if (
      (flags & ::File::FNM_DOTMATCH).zero? and not (
        # Don't add the negative lookahead if we have a pattern matching an explicit '\.' (escaped).
        subpatterns.first.first.eql?(?\\.ord) and not subpatterns.first[2].eql?(?..ord)
      )
    )

    # Exclude the CWD path ('.') and the parent ('..') path when `::File::FNM_GLOB_SKIPDOT` is flagged.
    # We can have both lookaheads with no conflict, e.g.:
    #   irb> /\A(?![\.])(?![\.]{1,2}\Z).*\Z/ === 'profile'  => true
    #   irb> /\A(?![\.])(?![\.]{1,2}\Z).*\Z/ === '.profile' => false
    #   irb> /\A(?![\.])(?![\.]{1,2}\Z).*\Z/ === '.'        => false
    #   irb> /\A(?![\.])(?![\.]{1,2}\Z).*\Z/ === '..'       => false
    #   irb> /\A(?![\.]{1,2}\Z).*\Z/         === '..'       => false
    #   irb> /\A(?![\.]{1,2}\Z).*\Z/         === '.'        => false
    #
    # This matches MRI's `::Dir::glob` behavior as of Ruby 3.1: https://bugs.ruby-lang.org/issues/17280
    subpatterns.unshift(*[?(, ??, ?!, ?[, ?\\, ?., ?], ?{, ?1, ?,, ?2, ?}, ?\\, ?Z, ?)].map!(&:ord)) unless (
      (flags & ::File::FNM_SKIP_DOT).zero?
    ) if defined?(::File::FNM_SKIP_DOT)
    # TODO: Require Ruby 3.1

    # Add an explicit beginning/end-of-`::String` Anchor to our pattern:
    # https://ruby-doc.org/core/Regexp.html#class-Regexp-label-Anchors
    #
    # NOTE: Ensure this is the last modification made to the subpatterns before `#pack`ing,
    #       because these Anchors *must* be the first and last parts (respectively) of the packed `::String`.
    subpatterns.push(?\\.ord, ?Z.ord).unshift(?\\.ord, ?A.ord)

    # Enable `::Regexp` Option flags with a bitwise `OR` in `::Regexp::new`'s second argument:
    # https://ruby-doc.org/core/Regexp.html#class-Regexp-label-Options
    ::Regexp::new(
      subpatterns.flatten.pack('U*'),
      ((flags & ::File::FNM_CASEFOLD).zero? ? 0 : ::Regexp::IGNORECASE)
    )
  end
end
