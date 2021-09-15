begin
  require(-'extattr') unless defined?(::ExtAttr)
rescue ::LoadError
  # TODO: Remove this load guard and convert gemspec from development dependency
  #       once there is a `::Ractor`-safe version of `::ExtAttr` on rubygems-dot-org:
  #       https://github.com/dearblue/ruby-extattr/pull/1
end

module ::CHECKING::YOU::OUT::GHOST_REVIVAL
  # Check the filesystem extended attributes for manually-defined types.
  #
  # These attributes should contain IETF-style `media/sub`-type Strings,
  # but they are technically freeform and must be assumed to contain anything.
  # It's very very unlikely that anybody will ever use one of these at all,
  # but hey how cool is it that we will support it if they do? :)
  SUPPORTED_XATTR_NAMES = [

    # The freedesktop-dot-org specification is `user.mime_type`: https://www.freedesktop.org/wiki/CommonExtendedAttributes/
    # That leading `user` facet is the namespace which is handled by the `namespace` argument to `ruby-extattr`'s methods.
    #
    # Apache's `mod_mime_xattr` will look for this one: http://0pointer.net/blog/projects/mod-mime-xattr.html
    #
    # `curl` will use this one if given its `--xattr` argument: https://everything.curl.dev/usingcurl/downloads#storing-metadata-in-file-system
    -'mime_type',

    # At least one other application I can find (lighttpd a.k.a. "lighty")
    # will use `Content-Type` just like would be found in an HTTP header:
    # https://redmine.lighttpd.net/projects/1/wiki/Mimetype_use-xattrDetails
    -'Content-Type',

  ].freeze

  # On Lunix, "user extended attributes are allowed only for regular files and directories,
  # and access to user extended attributes is restricted to the owner and to users with
  # appropriate capabilities for directories with the sticky bit set."
  #
  # TOD0: Support other OS stuff like `MDItemContentType` on macOS.
  STEEL_NEEDLE = ::Ractor.make_shareable(proc { |pathname, receiver: ::Ractor::current|
    return unless pathname.exist?
    [::ExtAttr::USER, ::ExtAttr::SYSTEM].flat_map { |namespace|
      ::ExtAttr.list(pathname.to_s, namespace).keep_if(&SUPPORTED_XATTR_NAMES.method(:include?)).map! { |attr_name|
        ::ExtAttr::get(pathname.to_s, ::ExtAttr::USER, attr_name)
      }
    }.map! { ::CHECKING::YOU::IN::from_ietf_media_type(_1, receiver: receiver) }
  }) if defined?(::ExtAttr)

  # TODO: Remove this dummy proc along with the `require` guard at the top of this file.
  STEEL_NEEDLE = ::Ractor.make_shareable(proc { Array::new }) unless defined?(::ExtAttr)
end
