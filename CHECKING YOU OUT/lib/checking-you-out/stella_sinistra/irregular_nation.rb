module ::CHECKING::YOU::OUT::StellaSinistra

  # Types which should not get an `APPLICATION_OCTET_STREAM` parent.
  self::IRREGULAR_PHYLA = [
    :example,
    :inode,               # Things matched by `IRREGULAR_NATION`.
    :"x-content",         # Directory trees.
    :"x-scheme-handler",  # URI schemes.
  ].map!(&:freeze).freeze

  # Support the implicit `inode/*` types, as detailed in the "Non-regular files" section of
  # https://specifications.freedesktop.org/shared-mime-info-spec/shared-mime-info-spec-latest.html
  #
  # "Sometimes it is useful to assign MIME types to other objects in the filesystem,
  #  such as directories, sockets and device files. This could be useful when looking up an icon for a type,
  #  or for providing a textual description of one of these objects.
  #  The media type 'inode' is provided for this purpose, with the following types corresponding to
  #  the standard types of object found in a Unix filesystem:
  #   - `inode/blockdevice`
  #   - `inode/chardevice`
  #   - `inode/directory`
  #   - `inode/fifo`
  #   - `inode/mount-point`
  #   - `inode/socket`
  #   - `inode/symlink`"
  self::HOUSE_NATION = [
    :blockdevice,
    :chardevice,
    :directory,
    :fifo,
    :"mount-point",
    :socket,
    :symlink,
  ].yield_self {
      ::Hash[_1.zip(_1.map { |genus| ::CHECKING::YOU::OUT::new(:possum, :inode, genus) })]
  }.tap { |house|
    # "An `inode/mount-point` is a subclass of `inode/directory`.
    #  It can be useful when adding extra actions for these directories, such as 'mount' or 'eject'.
    #  Mounted directories can be detected by comparing the 'st_dev' of a directory with that of its parent.
    #  If they differ, they are from different devices and the directory is a mount point."
    house[:"mount-point"].add_parent(house[:directory])
  }.transform_values!(&:freeze).freeze


  # Return a non-regular (`inode`) type for a given `Pathname`.
  IRREGULAR_NATION = ::Ractor::make_shareable(proc { |pathname|
    # NOTE: There's another way to do this with `File::Stat#ftype` which returns a `String` describing the type:
    # one of `file`, `directory`, `characterSpecial`, `blockSpecial`, `fifo`, `link`, `socket`, or `unknown`,
    # but I am going to fall through a `case` calling each of the single-purpose helper methods (e.g. `#blockdev?`)
    # to avoid allocating a new `String` and because those helper methods also all exist in `Pathname`
    # which also gives us `#mountpoint?` so we don't have to compare directories' `dev` with their parent's.
    #
    # A potential source of confusion here is the dissimilarity of some `#ftype` `String`s with their helper methods,
    # particularly `"fifo"`/`#pipe?` for people not well-versed enough in Lunix to know those are the same.
    self::HOUSE_NATION[
      case
      when pathname.blockdev?   then :blockdevice
      when pathname.chardev?    then :chardevice
      when pathname.mountpoint? then :"mount-point"  # MUST come before `:directory`.
      when pathname.directory?  then :directory
      when pathname.pipe?       then :fifo
      when pathname.socket?     then :socket
      when pathname.symlink?    then :symlink
      end
    ]
  })

end  # module ::CHECKING::YOU::IN::StellaSinistra
