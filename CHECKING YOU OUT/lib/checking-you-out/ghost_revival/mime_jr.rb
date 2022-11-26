require(-'ox') unless defined?(::Ox)
require(-'set') unless defined?(::Set)

# Endian-swapping methods.
require('xross-the-xoul/cpu') unless defined?(::XROSS::THE::CPU)

require_relative(-'../vinculum_stellarum/astraia_no_soubei') unless defined?(::CHECKING::YOU::OUT::ASTRAIAの双皿)

# Define a custom `Set` subclass to identify the return values from `MIMEjr` that should be passed to `MrMIME`.
::CHECKING::YOU::OUT::BatonPass = ::Class.new(::Set)

# Push-event-based parser for freedesktop-dot-org `shared-mime-info`-format XML package files,
# including the main `shared-mime-info` database itself (GPLv2+), Apache Tika (MIT), and our own (AGPLv3).
# https://specifications.freedesktop.org/shared-mime-info-spec/shared-mime-info-spec-latest.html
# https://gitlab.freedesktop.org/xdg/shared-mime-info/-/blob/master/src/update-mime-database.c
#
#
# Example pulled from `freedesktop.org.xml.in`:
#
#   <mime-type type="application/vnd.oasis.opendocument.text">
#     <comment>ODT document</comment>
#     <acronym>ODT</acronym>
#     <expanded-acronym>OpenDocument Text</expanded-acronym>
#     <sub-class-of type="application/zip"/>
#     <generic-icon name="x-office-document"/>
#     <magic priority="70">
#       <match type="string" value="PK\003\004" offset="0">
#         <match type="string" value="mimetype" offset="30">
#           <match type="string" value="application/vnd.oasis.opendocument.text" offset="38"/>
#         </match>
#       </match>
#     </magic>
#     <glob pattern="*.odt"/>
#   </mime-type>
#
# This `jr` handler focuses builds `::CHECKING::YOU::IN` key `Struct`s by on-the-fly matching
# of given `Pathname` or `IO`-like objects.
class ::CHECKING::YOU::OUT::MIMEjr < ::Ox::Sax

  # Callback methods we can implement in this Handler per http://www.ohler.com/ox/Ox/Sax.html
  #
  # def instruct(target); end
  # def end_instruct(target); end
  # def attr(name, str); end
  # def attr_value(name, value); end
  # def attrs_done(); end
  # def doctype(str); end
  # def comment(str); end
  # def cdata(str); end
  # def text(str); end
  # def value(value); end
  # def start_element(name); end
  # def end_element(name); end
  # def error(message, line, column); end
  # def abort(name); end
  #
  # PROTIPs:
  # - Our callback methods must be public or they won't be called!
  # - Some argument names in the documented method definitions describe the type (in the Ruby sense)
  #   of the argument, and some argument names describe their semantic meaning w/r/t the XML document!
  #   - Arguments called `name` will be Symbols by default unless `Ox::parse_sax` was given
  #     an options hash where `:symbolize` => `false` in which case `name` arguments will contain Strings.
  #   - Arguments called `str` will be Strings always.
  #   - Arguments called `value` will be `Ox::Sax::Value` objects that can be further differentiated in several ways:
  #     http://www.ohler.com/ox/Ox/Sax/Value.html
  # - For example, an invocation of `attr(name, str)` emitted while parsing a fd.o `<magic>` Element might have
  #   a `name` argument containing the Symbol `:priority` and a `str` argument containing its String value e.g. `"50"`.
  # - The `value` versions of these callback methods have priority over their `str` equivalents
  #   if both are defined, and only one of them will ever be called,
  #   e.g. `attr_value()` > `attr()` iff `defined? attr_value()`.


  # `::Regexp` to match partial C-style escapes in our value `::String`s.
  #
  # Per the `shared-mime-info` manual:
  # "The string type supports the C character escapes (\0, \t, \n, \r, \xAB for hex, \777 for octal)."
  ESCAPE_FROM_NEW_STRING = %r&
    \\(
      (x)([\dA-Fa-f]{1,2}) |
      (\d{1,3})            |
      ([rnt\\])
    )
  &xim

  # `::Regexp` to match valid base-prefixed Numeric literals.
  #
  # Per https://docs.ruby-lang.org/en/master/doc/syntax/literals_rdoc.html#label-Numbers —
  # "You can use a special prefix to write numbers in decimal, hexadecimal, octal or binary formats.
  #  For decimal numbers use a prefix of `0d`, for hexadecimal numbers use a prefix of `0x`,
  #  for octal numbers use a prefix of `0` or `0o`, for binary numbers use a prefix of `0b`.
  #  The alphabetic component of the number is not case-sensitive."
  #
  # Ruby supports underscores (`_`) in Numeric literals for readability, e.g.
  #   `irb> 0x1337_BEEF == 0x1337BEEF => true`, so include those too!
  LITERALLY_FIGURATIVE = /^0[dxob]?[_\h]+$/

  # Turn an arbitrary String into its correctly-based Integer or into an unescaped String.
  BASED_STRING = ::Ractor.make_shareable(proc {
    # If the given `::String` matches for format of a `::Numeric` literal then
    # this `::Proc` will return a `::Numeric`, otherwise it will return a `::String`.
    # This is confusing/annoying but necessary to support masked sequence matches without the
    # allocation overhead of going back and forth between `::String` and `::Integer` representations.
    (LITERALLY_FIGURATIVE === _1) ?
      # There will always be a leading `0` in any `::Numeric` literal no matter the base.
      # Remove it so we can examine the next character for a base-decision.
      case _1.delete_prefix!(-?0).ord
        # The prefix is case-insensitive, so we can't just e.g. `#delete_prefix!(-?x)` here.
        # Operating on codepoints allows us to avoid the allocation overhead of even a single-char like `?x`.
        when 88, 120 then _1.slice!(1...).to_i(16)  # Hexadecimal: `[?X, ?x].map!(&:ord) => [88, 120]`
        when 79, 111 then _1.slice!(1...).to_i(8)   #       Octal: `[?O, ?o].map!(&:ord) => [79, 111]`
        when 68, 100 then _1.slice!(1...).to_i(10)  #     Decimal: `[?D, ?d].map!(&:ord) => [68, 100]`
        when 66,  98 then _1.slice!(1...).to_i(2)   #      Binary: `[?B, ?b].map!(&:ord) => [66,  98]`
        else              _1.to_i(8)  # Numbers with only a leading `0` and no `[DdOaBbXx]` are octal.
      end :
      _1.force_encoding(
        # The source XML will always be in UTF-8, but we want a byte String.
        Encoding::ASCII_8BIT
      ).gsub(
        # "The string type supports the C character escapes (\0, \t, \n, \r, \xAB for hex, \777 for octal)."
        ESCAPE_FROM_NEW_STRING
      ) {
        case $1
        when -?r  then 13.chr
        when -?n  then 10.chr
        when -?t  then  9.chr
        when -?\\ then 92.chr  # e.g. `"{\\rtf"`
        else
          if $2.eql?(-?x) then $3.to_i(16).chr
          elsif $1.to_i.zero? then 0.chr
          else $1.to_i(8).chr
          end
        end
      }.-@  # Dedupe and freeze our `::String` output.
  })

  # `::Hash`` of converter methods for `shared-mime-info` content-match pattern formats.
  #
  # Per the `shared-mime-info` spec:
  # "All numbers are in network (big-endian) order. This is necessary because the data will be
  # stored in arch-independent directories like `/usr/share/mime` or even in user's home directories."
  MAGIC_EYE = ::Ractor::make_shareable({
    :string   => BASED_STRING,
    :byte     => BASED_STRING,
    :big32    => BASED_STRING,
    :little32 => BASED_STRING >> ::XROSS::THE::CPU::method(:swap32),
    :host32   => BASED_STRING >> ::XROSS::THE::CPU::method(:swapBtoN),
    :big16    => BASED_STRING,
    :little16 => BASED_STRING >> ::XROSS::THE::CPU::method(:swap16),
    :host16   => BASED_STRING >> ::XROSS::THE::CPU::method(:swapBtoN),
  }.tap {

    # TODO: Actually implement `stringignorecase`. This is a Tika thing not found in the fd.o XML.
    _1[:stringignorecase] = _1[:string]

    # Returning `string` as default will probably not result in a successful match
    # but will avoid blowing up our entire program if we encounter an unhandled format.
    _1.default = _1[:string]
  })

  # These `Class`es can match the Media-Type `String` from `<mime-type>` and `<alias>`.
  # If there's a match, the matching `CYI`/`B4U` will be removed from `@needles`.
  IDENTITY_CLASSKEYS = [
    ::CHECKING::YOU::IN,
    ::CHECKING::YOU::IN::B4U
  ].freeze

  # Map of `shared-mime-info` XML Element names to our generic category names.
  FDO_ELEMENT_CATEGORY = {
    :magic              => :content_match,
    :treemagic          => :content_match,
    :"root-XML"         => :content_match,
    :match              => :content_match,
    :fourcc             => :content_match,  # TODO: Split this into a new category
    :glob               => :pathname_match,
    :alias              => :family_tree,
    :"sub-child-of"     => :family_tree,
    :"generic-icon"     => :host_metadata,
    :icon               => :host_metadata,
    :comment            => :textual_metadata,
    :acronym            => :textual_metadata,
    :"expanded-acronym" => :textual_metadata,
  }.freeze

  # `MrMIME::new` will take any of these keys as keyword arguments
  # whose value will override the default defined in this Hash.
  DEFAULT_LOADS = {
    :textual_metadata   => false,
    :host_metadata      => false,
    :pathname_match     => true,
    :content_match      => true,
    :family_tree        => true,
  }.freeze

  # You shouldn't abuse the power of the Solid.
  def category_skips
    @category_skips ||= self.class::DEFAULT_LOADS.merge(@category_toggles || ::Hash::new).keep_if { |_category, enable|
      enable == false
    }.keys.to_set
  end
  def element_skips
    @skips ||= self.class::FDO_ELEMENT_CATEGORY.select { |_element, category|
      self.category_skips.include?(category)
    }.keys.to_set
  end

  # Override the normal instantiation of our handler to wrap it in a `::Ractor`.
  def self.new(
    *handler_args,               # Will be passed to the handler's normal `::instantiate`.
    trainer: ::Ractor.current,   # `Ractor` in whose context we are instantiated.
    receiver: ::Ractor.current,  # `Ractor` to whom we will send our parse result messages.
    **handler_kwargs             # Will be passed to the handler's normal `::instantiate`.
  )
    # When we `::initialize` our handler `::Class` we will actually get a `::Ractor` instance,
    # and the normal handler instance will be wrapped inside it controlled by a simple message-handling loop.
    ::Ractor::new(
      self,      # Handler `Class` to be wrapped by `Ractor::new`.
      receiver,  # `Ractor` to whom we will send our parse result messages.
      *handler_args,
      name: "#{trainer.name} — #{self.name.split(-'::')[-1]}",  # e.g. `"CHECKING YOU OUT — MIMEjr"`.
      **handler_kwargs,
    ) { |handler_class, receiver_ractor, *handler_args, **handler_kwargs|

      # Do the thing `self.new` usually does, just wrapped inside this `Ractor` context.
      handler = handler_class.allocate.tap { _1.send(:initialize, receiver_ractor, *handler_args, **handler_kwargs) }

      # Forward `shared-mime-info` `::Pathname` subclasses from the main message-bus `Ractor`.
      # All parsers in our party MUST have the same `SharedMIMEinfo` state or we will get confusing results,
      # but the main message-bus `Ractor` will have send the same message to all other parsers too.
      #
      # Spool search needles with `#awen`, and trigger a search for those needles when we are sent
      # our haystack-containing `::Set` subclass (`BatonPass`) or `true` if no haystack is needed.
      while message = ::Ractor.receive
        case message
        when ::CHECKING::YOU::IN::EverlastingMessage then
          (message.chain_of_pain == self) ? handler.awen(message.in_motion) : handler.do_the_thing(message)
        when ::CHECKING::YOU::OUT::GHOST_REVIVAL::DISCOVER_THE_LIFE::SharedMIMEinfo then handler.toggle_package(message)
        else handler.awen(message)
        end
      end
    }  # ::Ractor::new
  end

  # Instantiate parse environment for `MIMEjr` and also for `MrMIME` (subclass).
  def initialize(receiver_ractor, *handler_args, keep_packages_open: true, **handler_kwargs)
    # Per the `Ox::Sax` dox:
    # "Initializing `line` attribute in the initializer will cause that variable to
    #    be updated before each callback with the XML line number.
    #  The same is true for the `column` attribute, but it will be updated with
    #    the column in the XML file that is the start of the element or node just read.
    #  `@pos`, if defined, will hold the number of bytes from the start of the document."
    #@pos = nil
    #@line = nil
    #@column = nil

    # `::Ractor`-specific stuff.
    @receiver_ractor = receiver_ractor

    # Container for enabled `SharedMIMEinfo` paths and their opened `IO` streams.
    @mime_packages = ::Hash.new
    @keep_packages_open = keep_packages_open

    # Scratch `String` for the currently-parsing Media-Type, used to instantiate `self.cyo`
    # iff we have a match.
    @media_type = ::String.new

    # Container `::Hash` for search queries, containing one `::Set` subclass per `class` of needle.
    # I am using a subclass here so the handlers' `::Ractor` message loops can easily distinguish
    # `::Ractor`-to-`::Ractor` communication from outside `::Set` messages.
    @needles = ::Hash.new { _1[_2] = ::CHECKING::YOU::OUT::BatonPass.new }
    # Clear all member `::Set`s when `#clear`ing the `::Hash` itself.
    @needles.define_singleton_method(:clear) {
      self.values.each(&:clear)
      super()
    }

    # We receive separate events for Elements and Attributes, so we need to keep track of
    # the current Element to know what to do with Attributes since we can't rely on Attribute
    # names to be unique. For example, `shared-mime-info` has an attribute `type` on
    # `<mime-type>`, `<alias>`, `<match>`, and `<sub-class-of>`.
    @parse_stack = ::Array.new

    # We need a separate stack (`@cat_sequence`) and a flag boolean for building content-match structures since
    # the source XML represents OR and AND byte-sequence relationships as sibling and child Elements respectively,
    # e.g. `<magic><match1><match2/><match3/></match1><match4/></magic>` => `[m1 AND m2]` OR `[m1 AND m3]`, OR `[m4]`.
    # When the flag is set, any call to `#pop` from the `@cat_sequence` stack (in our `end_element` method)
    # should first save the complete stack as a content-match candidate. If the flag is not set, just `#pop` but then stop.
    #
    # `<treemagic><treematch/></treemagic>` work the same way.
    @i_can_haz_filemagic = true
    @i_can_haz_treemagic = true

    # Allow the user to control the conditions on which we ignore Elements from the source XML.
    @category_toggles = handler_kwargs.slice(*self.class::DEFAULT_LOADS.keys)

    # Here's where I would put a call to `super()` a.k.a `Ox::Sax#initialize` — IF IT HAD ONE
  end

  # Decompose search needles into a retained container based on each needle's `class`.
  # Support single needle messages and messages containing an `Enumerable` of needles.
  def awen(needle)
    case needle
    when ::CHECKING::YOU::IN::B4U then
      # This `::Set` subclass describes composite types like `image/svg+xml` as a group of CYIs.
      # The structure itself should be used as a key, but its inividual members should be used too.
      needle.each { @needles[_1.class].add(_1) }
      @needles[needle.class].add(needle)
    when ::Array, ::Set then needle.each { @needles[_1.class].add(_1) }
    else @needles[needle.class].add(needle)
    end
  end

  # Enable/disable a certain `shared-mime-info` XML package file.
  def toggle_package(xml_pathname)
    # This will work even with different objects of the same path:
    #   irb> Pathname.new("/tmp").eql? Pathname.new("/tmp") => true
    #   irb> Pathname.new("/tmp").hash == Pathname.new("/tmp").hash => true
    if @mime_packages.has_key?(xml_pathname) then
      @mime_packages.delete(xml_pathname)
    else
      # Open package files immediately if so configured.
      # Otherwise they will be opened at search time and then re-closed.
      @mime_packages.store(xml_pathname, @keep_packages_open ? self.open_package(xml_pathname) : nil)
    end
  end

  # Open an XML package file for reading given its `::Pathname` and return the `::IO` stream object.
  def open_package(pathname, **kwargs)
    pathname.open(mode=File::Constants::RDONLY).tap {
      # "Announce an intention to access data from the current file in a specific pattern.
      # On platforms that do not support the posix_fadvise(2) system call, this method is a no-op."
      #
      # This was probably a bigger deal when we all stored our files on spinning rust, but it shouldn't hurt :)
      #
      # I'm using `:sequential` because I am doing event-based XML parsing, and I'm avoiding `:noreuse`
      # because back-to-back invocations of DistorteD will benefit from the OS caching the data files.
      #
      # N0TE: `:noreuse` is a no-op on Lunix anyway, at least as of ver 5.12 as I write this in 2021:
      # https://linux.die.net/man/2/posix_fadvise
      # https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/mm/fadvise.c
      # https://web.archive.org/web/20130513093816/http://kerneltrap.org/node/7563
      #
      # But it works on FreeBSD, amusingly even when using Linux ABI compat:
      # https://www.freebsd.org/cgi/man.cgi?query=posix_fadvise&sektion=2
      # https://cgit.freebsd.org/src/tree/sys/kern/vfs_syscalls.c
      # https://cgit.freebsd.org/src/tree/sys/compat/linux/linux_file.c
      #
      # Other interesting-though-not-particularly-useful-or-relevant links:
      # https://pubs.opengroup.org/onlinepubs/007904975/functions/posix_fadvise.html  (2004 edition)
      # https://pubs.opengroup.org/onlinepubs/9699919799/functions/posix_fadvise.html (2018 edition)
      # https://groups.google.com/g/lucky.linux.fsdevel/c/5aBm_HWW6zI                 (2002 Lunix discussion)
      # https://en.wikipedia.org/wiki/Open_(system_call)                              (The system call Ruby wraps)
      # https://en.wikipedia.org/wiki/File_descriptor                                 (That to which the advise applies)
      #
      # Per `man 2 posix_fadvise`:
      #   "`POSIX_FADV_SEQUENTIAL` — The application expects to access the specified data sequentially
      #                              (with lower offsets read before higher ones)."
      #   "`POSIX_FADV_WILLNEED`  — initiates a nonblocking read of the specified region into the page cache."
      #
      # Choose `:willneed` if we are opening a file descriptor and keeping it open even while not actively parsing.
      # Choose `:sequential` if we are opening a new file descriptor every time we do a parse.
      _1.advise(@keep_packages_open ? :willneed : :sequential)
    }
  end

  # Callback for the start of any XML Element.
  # This handler will only need to parse the container `<mime-info>`/`<mime-type>` elements,
  # `<glob>` elements (for filename matching), and `<magic>`/`<match>` elements (for content matching).
  def start_element(name)
    # Record the current state of the parser Element stack regardless of our decision to skip its contents.
    @parse_stack.push(name)
    return if self.element_skips.include?(name)

    # Skip this Element iff we have no relevant needles,
    # e.g. skip `<magic>`/`<match>` elements if we have no `IO`-like content-match needles,
    #      and skip `<glob>` elements if we have no `::Pathname`-like filename-match needles.
    # This SHOULD be exactly repeated in `attr_value` and `end_element` for full benefits.
    return if case name
      when :magic,     :match     then @needles[::CHECKING::YOU::OUT::GHOST_REVIVAL::Wild_I∕O].empty?
      when :treemagic, :treematch then @needles[::Dir].empty?
      when :glob                  then (
        @needles[::CHECKING::YOU::OUT::GHOST_REVIVAL::Wild_I∕O].empty? and
        @needles[::CHECKING::YOU::OUT::ASTRAIAの双皿].empty?           and
        @needles[::CHECKING::YOU::OUT::StellaSinistra].empty?          and
        @needles[::CHECKING::YOU::OUT::DeusDextera].empty?
      )
      when :"root-XML"            then @needles[::CHECKING::YOU::OUT::SweetSweet♥Magic::ReRoots].empty?
      when :alias                 then (
        @needles[::CHECKING::YOU::IN].empty? and
        @needles[::CHECKING::YOU::IN::B4U].empty?
      )
      when :fourcc                then @needles[::CHECKING::YOU::OUT::AtomicAge::FourLeaf].empty?
    end

    # Otherwise set up needed container objects.
    case name
    when :match       then
      # Any time we add a new level of `<match>` to the `<magic>` stack,
      # the next `end_element(match)` will check the entire stack against our `@needles`.
      @i_can_haz_filemagic = true
      @cat_sequence.append(::CHECKING::YOU::OUT::SequenceCat::new)
    when :magic       then @cat_sequence = ::CHECKING::YOU::OUT::SpeedyCat::new if @cat_sequence.nil?
    when :treemagic   then @mother_tree  = ::CHECKING::YOU::OUT::SpeedyCat::new if @mother_tree.nil?
    when :treematch   then
      # Any time we add a new level of `<treematch>` to the `<treemagic>` stack,
      # the next `end_element(treematch)` will check the entire stack against our `@needles`.
      @i_can_haz_treemagic = true
      @mother_tree.append(::CHECKING::YOU::OUT::CosmicCat::new)
    when :glob        then @astraia      = ::CHECKING::YOU::OUT::ASTRAIAの双皿::new if @astraia.nil?
    when :"root-XML"  then @re_roots     = ::CHECKING::YOU::OUT::SweetSweet♥Magic::ReRoots::new if @re_roots.nil?
    when :fourcc      then @four_leaf    = ::CHECKING::YOU::OUT::AtomicAge::FourLeaf::new if @four_leaf.nil?
    end
  end

  # The meat of all our partial matches come in the form of element attributes for the elements
  # I discussed in the comments for the `start_element` method.
  def attr_value(attr_name, value)
    # NOTE: `parse_stack` can be empty here in which case its `#last` will be `nil`.
    # This happens e.g. for the two attributes of the XML declaration '<?xml version="1.0" encoding="UTF-8"?>'.
    return if self.element_skips.include?(@parse_stack.last)
    return if case @parse_stack.last
      when :magic,     :match     then @needles[::CHECKING::YOU::OUT::GHOST_REVIVAL::Wild_I∕O].empty?
      when :treemagic, :treematch then @needles[::Dir].empty?
      when :glob                  then (
        @needles[::CHECKING::YOU::OUT::GHOST_REVIVAL::Wild_I∕O].empty? and
        @needles[::CHECKING::YOU::OUT::ASTRAIAの双皿].empty?           and
        @needles[::CHECKING::YOU::OUT::StellaSinistra].empty?          and
        @needles[::CHECKING::YOU::OUT::DeusDextera].empty?
      )
      when :"root-XML"            then @needles[::CHECKING::YOU::OUT::SweetSweet♥Magic::ReRoots].empty?
      when :alias                 then (
        @needles[::CHECKING::YOU::IN].empty? and
        @needles[::CHECKING::YOU::IN::B4U].empty?
      )
      when :fourcc                then @needles[::CHECKING::YOU::OUT::AtomicAge::FourLeaf].empty?
    end

    case @parse_stack.last
    when :"mime-type" then
      @media_type.replace(value.as_s) if attr_name == :type
      @receiver_ractor.send(@media_type.dup, move: true) if @needles[::String].include?(@media_type) if attr_name == :type
    when :alias then
      return unless attr_name == :type
      alias_media_type = value.as_s
      return unless @needles[::String].include?(alias_media_type)
      IDENTITY_CLASSKEYS.each { |classkey_csupó|
        @needles[classkey_csupó].each {
          (
            @needles[classkey_csupó].delete(_1) &&
            ::CHECKING::YOU::IN::from_iana_media_type(@media_type.dup, receiver: @receiver_ractor)
          ) if _1.to_s.eql?(alias_media_type)
        }
      }
    when :magic then
      # Content-match byte-sequence container Element can specify a weight 0–100.
      @cat_sequence&.weight = value.as_i if attr_name == :priority
    when :match then
      # Parse the actual matching byte sequences.
      # Our `SpeedyCat`/`SequenceCat` `::Struct`s are written to handle these in any order,
      # which is why `#format` passes in a `proc` to be used if the order is `format` and then `value` :)
      case attr_name
      when :type   then @cat_sequence.last.format   = MAGIC_EYE[value.as_sym]
      when :value  then @cat_sequence.last.sequence = value.as_s
      when :offset then @cat_sequence.last.boundary = value.as_s
      when :mask   then @cat_sequence.last.mask     = value.as_s
      end
    when :treemagic then
      # Content-match byte-sequence container Element can specify a weight 0–100.
      @mother_tree&.weight = value.as_i if attr_name == :priority
    when :treematch then
      # Rename the most common keys to avoid confusion with other 'type's and 'path's in CYO-land.
      case attr_name
      when :path         then @mother_tree.last.here_we_are    = ::Pathname::new(value.as_s)
      when :type         then @mother_tree.last.your_body      = value.as_s
      when :"match-case" then @mother_tree.last.case_sensitive = value.as_bool
      when :executable   then @mother_tree.last.executable     = value.as_bool
      when :"non-empty"  then @mother_tree.last.non_empty      = value.as_bool
      when :mimetype     then @mother_tree.last.inner_spirit   = value.as_s
      end
    when :glob then
      # Parse filename matches.
      case attr_name
      when :weight           then @astraia.weight = value.as_i
      when :pattern          then @astraia.replace(value.as_s)
      when :"case-sensitive" then @astraia.case_sensitive = value.as_bool
      end
    when :"root-XML" then
      case attr_name
      when :namespaceURI then @re_roots.namespace = value.as_s
      when :localName    then @re_roots.localname = value.as_s
      end
    when :fourcc         then
      case attr_name
      when :type         then @four_leaf.format   = MAGIC_EYE[value.as_sym]
      when :value        then @four_leaf.fourcc = value.as_s
      end
    end
  end

  # Callback for end-of-element events, i.e. the opposite of `start_element`.
  # Used to clean up scratch variables or save a successful match.
  def end_element(name)
    # The element won't be in the `parse_stack` if we skipped it in `start_element` too.
    return if self.element_skips.include?(@parse_stack.last)
    raise ::Exception.new('Parse stack element mismatch') unless @parse_stack.pop == name
    return if case name
      when :magic, :match         then @needles[::CHECKING::YOU::OUT::GHOST_REVIVAL::Wild_I∕O].empty?
      when :treemagic, :treematch then @needles[::Dir].empty?
      when :glob                  then (
        @needles[::CHECKING::YOU::OUT::GHOST_REVIVAL::Wild_I∕O].empty? and
        @needles[::CHECKING::YOU::OUT::ASTRAIAの双皿].empty?           and
        @needles[::CHECKING::YOU::OUT::StellaSinistra].empty?          and
        @needles[::CHECKING::YOU::OUT::DeusDextera].empty?
      )
      when :"root-XML"            then @needles[::CHECKING::YOU::OUT::SweetSweet♥Magic::ReRoots].empty?
      when :alias                 then (
        @needles[::CHECKING::YOU::IN].empty? and
        @needles[::CHECKING::YOU::IN::B4U].empty?
      )
      when :fourcc                then @needles[::CHECKING::YOU::OUT::AtomicAge::FourLeaf].empty?
    end

    case name
    when :magic then @cat_sequence.clear
    when :match then
      # The `<magic>` stack represents a complete match only the first time we encounter end_element(match)
      # after pushing a `<match>` to the `<magic>` stack and setting `@i_can_haz_filemagic = true`.
      if @i_can_haz_filemagic
        ::CHECKING::YOU::IN::from_iana_media_type(
          @media_type.dup,
          receiver: @receiver_ractor,
        ) if @needles[::CHECKING::YOU::OUT::GHOST_REVIVAL::Wild_I∕O].map(&:stream).map! {
          @cat_sequence.=~(_1, offset: @cat_sequence.min)
        }.any?
      end
      @cat_sequence.pop
      @i_can_haz_filemagic = false
    when :treemagic then @mother_tree.clear
    when :treematch then
      # The `<treemagic>` stack represents a complete match only the first time we encounter end_element(treematch)
      # after pushing a `<treematch>` to the `<treemagic>` stack and setting `@i_can_haz_treemagic = true`.
      if @i_can_haz_treemagic
        ::CHECKING::YOU::IN::from_iana_media_type(@media_type.dup, receiver: @receiver_ractor) if (
          @needles[::Dir].map { @mother_tree.=~(_1) }.any?
        )
        # Send any `mimetype` CYIs to `MrMIME` for `<treematch>` elements which want a certain inner file type.
        @mother_tree.map(&:inner_spirit)&.compact&.each(&@receiver_ractor.method(:send))
      end
      @mother_tree.pop
      @i_can_haz_treemagic = false
    when :glob then
      ::CHECKING::YOU::IN::from_iana_media_type(@media_type.dup, receiver: @receiver_ractor) if (
        @needles[::CHECKING::YOU::OUT::GHOST_REVIVAL::Wild_I∕O].map(&:astraia).map!(&@astraia.method(:eql?)).any? or
        @needles[::CHECKING::YOU::OUT::ASTRAIAの双皿].map(&@astraia.method(:eql?)).any?                           or
        @needles[::CHECKING::YOU::OUT::StellaSinistra].map(&@astraia.method(:eql?)).any?                          or
        @needles[::CHECKING::YOU::OUT::DeusDextera].map(&@astraia.method(:eql?)).any?
      )
    when :"root-XML" then
      ::CHECKING::YOU::IN::from_iana_media_type(@media_type.dup, receiver: @receiver_ractor) if (
        @needles[::CHECKING::YOU::OUT::SweetSweet♥Magic::ReRoots].map(&@re_roots.method(:eql?)).any?
      ) unless @re_roots.nil? or @re_roots&.empty?
      @re_roots.clear unless @re_roots.nil? or @re_roots&.empty?
    when :fourcc then
      ::CHECKING::YOU::IN::from_iana_media_type(@media_type.dup, receiver: @receiver_ractor) if (
        @needles[::CHECKING::YOU::OUT::AtomicAge::FourLeaf].map(&@four_leaf.method(:eql?)).any?
      ) unless @four_leaf.nil? or @four_leaf&.empty?
      @four_leaf.clear unless @four_leaf.nil? or @four_leaf&.empty?
    end
  end

  # Trigger a search for all needles received by our `::Ractor` since the last `#search`.
  # See the overridden `self.new` for more details of our `::Ractor`'s message-handling loop.
  def do_the_thing(the_trigger_of_innocence)
    # Use the value of our `EverlastingMessage` as a needle.
    self.awen(the_trigger_of_innocence.in_motion)

    # Check for filesystem extended attributes in `::Pathname` needles representing extant files.
    # Send their `CYI`s directly to `MrMIME` (`@receiver_ractor`) if found.
    @needles[::CHECKING::YOU::OUT::GHOST_REVIVAL::Wild_I∕O].map(&:pathname).keep_if(&:exist?).flat_map {
      ::CHECKING::YOU::OUT::VinculumStellarum::STEEL_NEEDLE.call(_1, receiver: @receiver_ractor)
    }

    # HACK: Use `Dir` as a needle key to represent the `Set` of `Pathname` needles representing extant directories.
    #       If there are none, we will skip `<treemagic>`/`<treematch>` elements for speed.
    #       Do it once here before parsing to avoid hitting the filesystem every time we encounter those elements.
    #       We don't use `Dir` needles for anything, so this behavior won't conflict.
    @needles[::Dir].merge(
      @needles[::CHECKING::YOU::OUT::GHOST_REVIVAL::Wild_I∕O].map(&:pathname).keep_if(&:directory?)
    )

    # HACK: Pull an additional file-extension needle out of our path needles.
    @needles[::CHECKING::YOU::OUT::GHOST_REVIVAL::Wild_I∕O].map(&:sinistar).each {
      @needles[_1.class].add(_1)
    }

    # HACK: Do a one-time `String`-ification of CYI-like keys since we need to do a lot of comparisons of them
    #       and don't want to be allocating them over and over.
    # TODO: Do the same for Glob-like keys.
    @needles[::String].merge(
      @needles[::CHECKING::YOU::IN].map(&:to_s)
    ).merge(
      @needles[::CHECKING::YOU::IN::B4U].map(&:to_s)
    )

    # Parse our enabled `shared-mime-info` packages for filename glob matches and content (magic) matches.
    self.parse_mime_packages

    # Any matched `::CHECKING::YOU::IN`s are forwarded to `@receiver_ractor` at time of `:end_element`,
    # so once we've exhausted all possible matches we can tell `@receiver_ractor` to do its own parse.
    # It's much faster to wait and do a single pass rather than trigger `@receiver_ractor` on-the-fly.
    @receiver_ractor.send(the_trigger_of_innocence, move: true)
    @needles.clear
  end

  # Kick off the actual process of parsing our enabled `SharedMIMEinfo` XML packages against any enabled `@needle`s.
  def parse_mime_packages(**kwargs)

    # Welcome to `::Class` 17!
    # Your file descriptor has been opened — or *re*opened — to parse one of our finest
    # remaining `shared-mime-info` XML packages.
    @mime_packages.each_pair { |(xml_pathname, xml_fd)|
      # This is where I would use `::Hash#transform_pair!` if there were such a method.
      # There are `#transform_values!` and `#transform_keys!` methods to alter `self` in place,
      # but I need to have the `xml_pathname` key to be able to set its value.
      # There is regular-old-`#map`, but that allocates a new `::Hash`, and I want to alter this one.
      if xml_fd.nil? then
        # Open and tell the kernel how we plan to use this file descriptor.
        @mime_packages.store(xml_pathname, self.open_package(xml_pathname))
      elsif xml_fd.closed? then
        # AFAICT we don't need to re-`fadvise` when reopening the same file descriptor.
        @mime_packages[xml_pathname].reopen(xml_pathname)
      else next  # Nothing to do if the file descriptor is already open.
      end
    }

    # Send each file descriptor through `::Ox`'s `sax_parse` method using our own `self` as the handler.
    @mime_packages.each_pair { |xml_pathname, xml_fd|
      # Docs: http://www.ohler.com/ox/Ox.html#method-c-sax_parse
      #
      # Code for this method is defined in Ox's C extension, not in Ox's Ruby lib:
      #   https://github.com/ohler55/ox/blob/master/ext/ox/ox.c  CTRL+F "call-seq: sax_parse".
      #   (Not linking a particular line number since that would require linking a particular revision too)
      #
      # Here is an actual example `<magic><match/>` element pulled from `freedesktop.org.xml`
      # showing why I am using Ox's `:convert_special` here:
      #   `<match type="string" value="&lt;&lt;&lt; QEMU VM Virtual Disk Image >>>\n" offset="0"/>`
      #
      # I can't figure out how exactly `:skip_none` and `:skip_off` differ here.
      # They appear a few times as equal/fall-through `case`s in some C extension `switch` statements:
      #   https://github.com/ohler55/ox/search?q=OffSkip
      #   https://github.com/ohler55/ox/search?q=NoSkip
      # In `sax.c`'s `read_text` function they are used slightly differently in the following conditional
      # where `:skip_none` checks if the end of the Element has been reached but `:skip_off` doesn't.
      #   https://github.com/ohler55/ox/blob/master/ext/ox/sax.c  CTRL+F "read_text"
      #   `((NoSkip == dr->options.skip && !isEnd) || (OffSkip == dr->options.skip)))`
      ::Ox::sax_parse(
        self,                     # Instance of a class that responds to `Ox::Sax`'s callback messages.
        xml_fd,                   # IO stream or String of XML to parse. Won't close File descriptors automatically.
        **{
          convert_special: true,  # [boolean] Convert encoded entities back to their unencoded form, e.g. `"&lt"` to `"<"`.
          skip: :skip_off,        # [:skip_none|:skip_return|:skip_white|:skip_off] (from Element text/value) Strip CRs, whitespace, or nothing.
          smart: false,           # [boolean] Toggle Ox's built-in hints for HTML parsing: https://github.com/ohler55/ox/blob/master/ext/ox/sax_hint.c
          strip_namespace: true,  # [nil|String|true|false] (from Element names) Strip no namespaces, all namespaces, or a specific namespace.
          symbolize: true,        # [boolean] Fill callback method `name` arguments with Symbols instead of with Strings.
          intern_strings: true,   # [boolean] Intern (freeze and deduplicate) String return values.
        }.update(kwargs),         # Let the sender override any of these defaults.
      )

      # We MUST `#rewind` each package's `::IO` stream if we are keeping the file descriptors open between parses,
      # otherwise subsequent calls to the sequential `::Ox::sax_parse` will complete instantly with no actual parsing
      # because it reads sequentially and doesn't reset the stream position itself.
      # If we aren't keeping file descriptors open we can just `#close` because the position will be reset to `0` when `#reopen`ing.
      @keep_packages_open ? xml_fd.rewind : xml_fd.close
    }  # @mime_packages.each_pair
  end
end

