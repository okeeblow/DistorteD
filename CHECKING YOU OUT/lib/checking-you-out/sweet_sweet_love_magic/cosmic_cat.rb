require(-'pathname') unless defined?(::Pathname)

require_relative(-'../weighted_action') unless defined?(::CHECKING::YOU::OUT::WeightedAction)

module ::CHECKING::YOU::OUT::SweetSweet♥Magic
  # Represent one possible link in a chain of tree branches for a successful directory match.
  #
  # "`<treemagic>` elements contain a list of `<treematch>` elements, any of which may match,
  #  and an optional `priority` attribute for all of the contained rules.
  #  The default priority value is `50`, and the maximum is `100`."
  #
  # "`<treematch>` elements can be nested, meaning that both the outer
  #  and the inner `<treematch>` must be satisfied for a 'match'."
  #
  # We avoid nesting by transforming the element trees into multiple flat `Array`s,
  # i.e. instances of this `Class` inside a `SpeedyCat`, or a single instance of this `Class`
  # on its own if there's only one level of `<treematch>` elements where the container would be a waste.
  CosmicCat = ::Struct::new(:here_we_are, :your_body, :case_sensitive, :executable, :non_empty, :inner_spirit) do
    include(::CHECKING::YOU::OUT::WeightedAction)

    # "A path that must be present on the mounted volume/filesystem.
    #  The path is interpreted as a relative path starting at the root of the tested volume/filesystem."
    def here_we_are=(otra)
      self[:here_we_are] = case otra
        when ::Pathname then otra
        when ::String   then ::Pathname::new(otra)
      end
    end

    # "The type of path. Possible values: `file`, `directory`, `link`"
    #
    # Avoid calling this `type` like in the XML since that's an overloaded term.
    def your_body=(otra)
      self[:your_body] = case otra
        when ::File, -'file',      :file      then :file
        when ::Dir,  -'directory', :directory then :directory
        when         -'link',      :link      then :link
      end
    end

    # "The mimetype for the file at path"
    #
    # Avoid calling this `mimetype` like in the XML since that's an overloaded term.
    def inner_spirit=(otra)
      self[:inner_spirit] = case otra
        when ::CHECKING::YOU::IN then otra
        when ::String            then ::CHECKING::YOU::IN::from_iana_media_type(otra)
      end
    end

    # Many `<treematch>` elements will have these unset. Return a false default for `nil`s.
    def executable?;     self[:executable]     || false; end
    def case_sensitive?; self[:case_sensitive] || false; end
    def non_empty?;      self[:non_empty]      || false; end

    # Match this structure against a `::Pathname` representing an extant directory.
    #
    # NOTE the official `Dir::glob` documentation about how "`File::FNM_CASEFOLD` is ignored" in `Dir::glob`,
    #      i.e. we can't use it to perform a case-insensitive match like with `File::fnmatch`.
    #      This is supported by the documentation for the constant itself:
    #      "Makes `File.fnmatch` patterns case insensitive (but not `Dir.glob` patterns)"
    #
    # Several forum and blog posts disagree with the official documentation and claim it works fine:
    # https://lostechies.com/derickbailey/2011/04/14/case-insensitive-dir-glob-in-ruby-really-it-has-to-be-that-cryptic/
    # https://www.ruby-forum.com/t/case-sensitivity-in-glob-revisited/110780/4
    # https://www.ruby-forum.com/t/whats-up-with-dir-glob/209794/5
    # https://www.ruby-forum.com/t/file-fnm-casefold-doesnt-work-for-dir-glob/98408/2
    #
    # However when I was developing `<treemagic>` support I couldn't get the `FNM_CASEFOLD` flag to work
    # and realized the documentation might be correct after all:
    #   irb> lumix = Pathname::new('/home/okeeblow/Works/DistorteD/CHECKING YOU OUT/TEST MY BEST/Try 2 Luv. U/x-content/image-dcf/LUMIX')
    #   irb> Dir::glob(Pathname::new('dcim'), File::FNM_CASEFOLD, base: lumix) => []
    #   irb> Dir::glob(Pathname::new('DCIM'), File::FNM_CASEFOLD, base: lumix) => ["DCIM"]
    #   irb> Dir::glob(Pathname::new('dcim*'), File::FNM_CASEFOLD, base: lumix) => ["DCIM"]
    #
    # Notice how it *does* work with the addition of the trailing asterisk to the pattern!
    # It works for multi-level patterns as well, but only if *every level* is given an asterisk:
    #   irb> svcd = Pathname::new('/home/okeeblow/Works/DistorteD/CHECKING YOU OUT/TEST MY BEST/Try 2 Luv. U/x-content/video-svcd/CYO-SVCD')
    #   irb> Dir::glob(Pathname::new('MPEG2/AVSEQ01.MPG'), File::FNM_CASEFOLD, base: svcd) => []
    #   irb> Dir::glob(Pathname::new('MPEG2/AVSEQ01.MPG*'), File::FNM_CASEFOLD, base: svcd) => []
    #   irb> Dir::glob(Pathname::new('MPEG2*/AVSEQ01.MPG*'), File::FNM_CASEFOLD, base: svcd) => ["mpeg2/avseq01.mpg"]
    #
    #
    # What gives? Time to delve into MRI source to find out:
    # - https://github.com/ruby/ruby/blob/master/dir.rb
    # - https://github.com/ruby/ruby/blob/master/dir.c
    #
    # In `dir.rb` we can see the method definition for `self.glob` and how it's just a Ruby-land wrapper
    # for `Primitive.dir_s_glob(pattern, flags, base, sort)`, meaning the `dir_s_glob` method defined in `dir.c`.
    #
    # Inside `dir_s_glob` we can see the bitwise operation disabling the `CASEFOLD` flag if it was given:
    # `const int flags = (NUM2INT(rflags) | dir_glob_option_sort(sort)) & ~FNM_CASEFOLD;`.
    # That is the "bitwise NOT (one's complement)" operator: https://en.wikipedia.org/wiki/Bitwise_operations_in_C#Bitwise_operators
    #
    # So why does it work with an asterisk added to the pattern? The following is speculation since this is
    # a difficult flow to follow, but here's what I think might be going on:
    #
    # Depending on if it was given a `String` glob pattern or an `Array` of patterns, `dir_s_glob` calls
    # either `rb_push_glob` or `dir_globs`. Both of those methods end up calling the `push_glob` method.
    #
    # If the current-working-directory (or the given `base:` directory) exists, `push_glob` calls `ruby_glob0`.
    # `ruby_glob0` expands any brace syntax in the pattern then calls `glob_make_pattern` to convert the
    # pattern `String` to a `glob_pattern`, a C `struct` which wraps the pattern `char*` along with a `glob_pattern_type`:
    # `enum glob_pattern_type { PLAIN, ALPHA, BRACE, MAGICAL, RECURSIVE, MATCH_ALL, MATCH_DIR }`.
    #
    # If the pattern is not "recursive" (uses the '**' directory-descending pattern), `glob_make_pattern` calls
    # `has_magic` to determine the other attributes for the pattern. Inside `has_magic`, the `MAGICAL` attribute is set
    # if the pattern contains the characters '*', '?', or '[' (EXTGLOB) but does not contain a '{' (`BRACE`).
    #
    # Back in `ruby_glob0`, the new `glob_pattern` is used when calling `glob_helper` to get the actual globbed directory contents.
    # Inside `glob_helper`, the `MAGICAL` `glob_make_pattern` makes us skip the short-circuit `goto literally`
    # in `if (!(norm_p || magical || recursive))`, then we hit a volume capabilities check in `is_case_sensitive` which,
    # if true, re-adds the `CASEFOLD` flag: `flags |= FNM_CASEFOLD` and is why adding the asterisk makes this work!
    #
    # TODO: Identify optical media for `x-content/blank-cd`, `x-content/blank-dvd`, `x-content/blank-bd`, and `x-content/blank-hddvd`.
    # TODO: Identify USB devices for e.g. `x-content/audio-player`.
    #
    # TODO: The above is no longer relevant and this is broken entirely as of
    #       https://bugs.ruby-lang.org/issues/14456 :(
    #       Come up with a new solution.
    def =~(otra)
      return if self.here_we_are.nil?
      case otra
      when ::Pathname then
        ::Dir::glob(
          self.case_sensitive? ?
            self[:here_we_are] :
            self[:here_we_are].to_s.split(::File::SEPARATOR).map!{ _1 << -?* }.join(::File::SEPARATOR),
          ::File::FNM_DOTMATCH | ::File::FNM_EXTGLOB | (self.case_sensitive? ? 0 : ::File::FNM_CASEFOLD),
          base: otra,
        ).pop&.yield_self(&otra.method(:join))&.yield_self { |globbed|
          # If we get here, the file/directory/link exists and has passed case-sensitivity check.
          case self.your_body
          when :file      then globbed.file?
          when :directory then globbed.directory?
          when :link      then globbed.symlink?
          end.tap { |match|
            match = globbed.executable? if self.executable?
            match = !globbed.empty?     if self.non_empty?
            # TODO: `mimetype`/`inner_spirit` matching — requires `together_4ever` to enrich this member to a `CYO`.
          }
        }
      else super
      end
    end  # =~

  end  # CosmicCat
end
