require(-'forwardable') unless defined?(::Forwardable)
require(-'pathname') unless defined?(::Pathname)

module ::CHECKING::YOU::OUT::GHOST_REVIVAL

  # Wrap `::Pathname`s alongside their `::IO` stream (from `#open`) and their extname-glob
  # so we can pass the entire thing around as a single unit.
  #
  # A lot of `::Pathname` is in C: https://github.com/ruby/ruby/blob/master/ext/pathname/pathname.c
  #             …and some in Ruby: https://github.com/ruby/ruby/blob/master/ext/pathname/lib/pathname.rb
  # Note the `rb_ext_ractor_safe(true);` :D
  #
  # TODO: Implement some sort of sliding-window `::IO#read` functionality here
  #       so `SequenceCat#=~` doesn't have to allocate and `#read` a throwaway byte `::String`
  #       for every matching attempt.
  #       https://blog.appsignal.com/2018/07/10/ruby-magic-slurping-and-streaming-files.html
  Wild_I∕O = ::Struct.new(:pathname, :stream, :stick_around) do

    def initialize(pathname)
      super(pathname.is_a?(::Pathname) ? pathname : ::Pathname.new(pathname), nil, nil)
    end

    def stream
      if self[:pathname].exist? and not self[:pathname].directory? then
        self[:stream] ||= self[:pathname].open(mode=::File::Constants::RDONLY|::File::Constants::BINARY).tap {
          # Tell the GC to close this stream when it goes out of scope.
          _1.autoclose = true
        }
      else nil
      end
    end

    def stick_around
      self[:stick_around] ||= ::CHECKING::YOU::OUT::StickAround.new(self[:pathname].to_s)
    end

    extend(::Forwardable)
    def_instance_delegators(
      :pathname,
      *::Pathname::instance_methods(false).difference(self.instance_methods(false))
    )

    # The `::Pathname` is the only one assumed to be set at all times, so `#hash` based on that.
    def hash; self[:pathname].hash; end

    # Empty out the `::Struct` so it can be re-used.
    def clear; self.tap { |get_wild| get_wild.members.each { |m| get_wild[m] = nil } }; end

    def eql?(otra)
      # TODO: Add `::IO`,`::String` etc here.
      case otra
      when ::Pathname then self[:pathname].eql?(otra)
      else super(otra)
      end
    end
    alias_method(:==, :eql?)

  end  # Wild_I∕O


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
  HOUSE_NATION = [
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
    HOUSE_NATION[case
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

end  # module ::CHECKING::YOU::IN::GHOST_REVIVAL
