# Override discovery of systemwide and user-specific MIME packages
# so we test only the single `fdo_mime` package.
module ::CHECKING::YOU::OUT::OnlyOnePackage
  # Path to CYO's bundled `shared-mime-info` main-package.
  FDO_MIME = ::Ractor::make_shareable(
    ::CHECKING::YOU::OUT::GHOST_REVIVAL::DISCOVER_THE_LIFE::SharedMIMEinfo.new(
      ::File.join(
        ::CHECKING::YOU::OUT::GEM_ROOT.call,
        -'mime',
        -'packages',
        -'third-party',
        -'shared-mime-info',
        "#{::CHECKING::YOU::OUT::GHOST_REVIVAL::DISCOVER_THE_LIFE::FDO_MIMETYPES_FILENAME}.in",
      )
    )
  )
  TIKA_MIME = ::Ractor::make_shareable(
    ::CHECKING::YOU::OUT::GHOST_REVIVAL::DISCOVER_THE_LIFE::SharedMIMEinfo.new(
      ::File.join(
        ::CHECKING::YOU::OUT::GEM_ROOT.call,
        -'mime',
        -'packages',
        -'third-party',
        -'tika-mimetypes',
        -'tika-mimetypes.xml',
      )
    )
  )
  CYO_MIME = ::Ractor::make_shareable(proc {
    cyo_base = ::CHECKING::YOU::OUT::GEM_ROOT.call
    ::Dir::glob(
      'mime/packages/*.xml',
      base: cyo_base
    ).map!(
      &cyo_base.method(:join)
    ).map!(
      &::CHECKING::YOU::OUT::GHOST_REVIVAL::DISCOVER_THE_LIFE::SharedMIMEinfo::method(:new)
    )
  })

  # TODO: Figure out why Refining our module (or module.singleton_class) doesn't work here.
  #refine ::CHECKING::YOU::OUT::GHOST_REVIVAL::DISCOVER_THE_LIFE.singleton_class do
  module ::CHECKING::YOU::OUT::GHOST_REVIVAL::DISCOVER_THE_LIFE
    def shared_mime_info_packages; ::Array.new.push(FDO_MIME).push(TIKA_MIME).push(*CYO_MIME.call); end
  end
end
