require(-'set') unless defined?(::Set)


# Decision-making matrix for various combinations of filename- and content-matches.
#
# Compare to `shared-mime-info` documentation's "Recommended checking order":
# https://specifications.freedesktop.org/shared-mime-info-spec/shared-mime-info-spec-latest.html
# (Not deep-linking because this page's section anchor names are auto-generated orz)
module ::CHECKING::YOU::OUT::GHOST_REVIVAL

  # NOTE: CYO deviates from `shared-mime-info`'s behavior very slightly here!
  #
  #
  # `shared-mime-info`'s "Recommended checking order" sez:
  #
  # - "Start by doing a glob match of the filename. Keep only globs with the biggest weight.
  #    If the patterns are different, keep only matched with the longest pattern."
  #    If after this, there is one or more matching glob, and all the matching globs result in
  #    the same mimetype, use that mimetype as the result."
  #
  # - "If the glob matching fails or results in multiple conflicting mimetypes,
  #    read the contents of the file and do magic sniffing on it.
  #    If no magic rule matches the data (or if the content is not available),
  #    use the default type of `application/octet-stream` for binary data,
  #    or `text/plain` for textual data.
  #    If there was no glob match, use the magic match as the result."
  #
  # - "If any of the mimetypes resulting from a glob match is equal to or a subclass of the result
  #    from the magic sniffing, use this as the result.
  #    This allows us for example to distinguish text files called 'foo.doc'
  #    from MS-Word files with the same name, as the magic match for the MS-Word file would be 
  #    `application/x-ole-storage` which the MS-Word type inherits."
  #
  # - "Otherwise use the result of the glob match that has the highest weight."
  #
  # Our behavior is identical except it allows glob matches which are a *superclass* of a
  # magic-match in addition to subclass or equal-to, i.e. using `:family_tree` for comparison here
  # instead of using `:kids_table`. There might be a downside to this that I haven't found yet
  # but it allows CYO to better match some things, e.g. matching a `'.flv'` video file as
  # `'video/x-flv'` instead of as `'video/x-javafx'`, since fd.o has the latter as a subclass of the former.
  #
  # "Note: Checking the first 128 bytes of the file for ASCII control characters is a good way to guess
  #  whether a file is binary or text, but note that files with high-bit-set characters should still be
  #  treated as text since these can appear in UTF-8 text, unlike control characters.
  MAGIC_CHILDREN = ::Ractor.make_shareable(proc { |glob, magic|
    case [glob, magic]
      in ::NilClass,           ::Hash               then magic.push_up
      in ::CHECKING::YOU::OUT, ::NilClass,          then glob
      in ::Hash,               ::NilClass,          then glob.push_up(:weight, :length)
      in ::Set,                ::NilClass,          then glob.max
      in ::Set,                ::Hash               then
        case
        when glob.empty? then magic.push_up
        when magic.empty? then glob.max
        else
          glob.select { not _1.adults_table.&(magic.values)&.empty? }&.yield_self { |magic_children|
            # If there are no glob-children-of-magic-matches, try the other way around.
            # This lets us match e.g. `application/x-mozilla-bookmarks` having a `text/html` glob match.
            magic_children.empty? ? magic.values.select { not _1.adults_table.&(glob)&.empty? }&.yield_self { |glob_children|
              glob_children.empty? ? glob.max : glob_children.max
            } : magic_children.max
          }
        end
      in ::Set,                ::CHECKING::YOU::OUT then glob & magic.kids_table
      in ::Hash,               ::Hash               then
        (glob.values.to_set & magic.values.to_set.map(&:family_tree).reduce(&:&)).yield_self { |magic_children|
          glob.keep_if { |_glob, cyo| magic_children.include?(cyo) }.push_up(:weight, :length)
        }
      in ::CHECKING::YOU::OUT, ::Hash               then
        magic&.empty? ? glob : glob.adults_table&.&(magic.values).yield_self {
          _1.empty? ? magic.push_up : glob
        }
      in ::Hash,               ::CHECKING::YOU::OUT then glob.values.compact.map!(&:adults_table).to_set & magic.kids_table
      in ::CHECKING::YOU::OUT, ::CHECKING::YOU::OUT then glob == magic ? glob : magic
      else ::CHECKING::YOU::OUT::GHOST_REVIVAL::APPLICATION_OCTET_STREAM
    end.yield_self(&POINT_ZERO)
  })

end  # ::CHECKING::YOU::IN::GHOST_REVIVAL
