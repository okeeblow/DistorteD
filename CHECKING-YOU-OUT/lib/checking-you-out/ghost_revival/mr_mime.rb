
require 'ox'


# Push-event-based parser for freedesktop-dot-org `shared-mime-info`-format XML package files,
# including the main `shared-mime-info` database itself (GPLv2+), Apache Tika (MIT), and our own (AGPLv3).
# https://specifications.freedesktop.org/shared-mime-info-spec/shared-mime-info-spec-latest.html
# https://gitlab.freedesktop.org/xdg/shared-mime-info/-/blob/master/src/update-mime-database.c
class CHECKING::YOU::MrMIME < ::Ox::Sax


  ORIGIN_OF_SYMMETRY = proc {
    # Little-endian systems:
    # - VAX
    # - x86 / AMD64
    # Big-endian systems:
    # - Motorola 68k
    # - Internet https://en.wikipedia.org/wiki/Endianness#Networking
    # - IBM mainframes
    # Bi-endian systems:
    # - AArch64
    # - PowerPC / POWER
    # - MIPS
    # - Alpha
    # - PA-RISC
    # - SuperH
    # - Itanium
    # - RISC-V
    @host_endianness ||= [1].yield_self { |bliss|
      # Pack the test Integer as a native-endianness 'I'nt and a 'N'etwork-endianess (BE) Int and compare.
      bliss.pack(-?I) == bliss.pack(-?N) ? :BE : :LE
    }
  }

  # Turn an arbitrary String into the correctly-based Integer it represents.
  # It would be nice if I could do this directly in `Ox::Sax::Value`.
  # Base-16 Ints can be written as literals in Ruby, e.g.
  # irb> 0xFF
  # => 255
  BASED_STRING = proc { |s|
    case
    when s[0..1].downcase == -'0x' then s.to_i(16)
    when s.chr == -?0 then s.to_i(8)
    else s.to_i(10)
    end
  }
  FDO_MAGIC_FORMATS = {
    # "The string type supports the C character escapes (\0, \t, \n, \r, \xAB for hex, \777 for octal)."
    -'string' => proc { |s| s },
    -'byte' => proc { |s| BASED_STRING.call(s).chr },
    -'little32' => proc { |s| BASED_STRING.call(s).yield_self { |value|
      ((value & 0xFF).chr + ((value >> 8) & 0xFF).chr + ((value >> 16) & 0xFF).chr + ((value >> 24) & 0xFF).chr)
    }},
    -'big32' => proc { |s| BASED_STRING.call(s).yield_self { |value|
      (((value >> 24) & 0xFF).chr + ((value >> 16) & 0xFF).chr + ((value >> 8) & 0xFF).chr + (value & 0xFF).chr)
    }},
    -'little16' => proc { |s| BASED_STRING.call(s).yield_self { |value|
      ((value & 0xFF).chr + (value >> 8).chr)
    }},
    -'big16' => proc { |s| BASED_STRING.call(s).yield_self { |value|
      ((value >> 8).chr + (value & 0xFF).chr)
    }},
  }.tap { |f|

      # TODO: Actually implement `stringignorecase`. This is a Tika thing not found in the fd.o XML.
      f[-'stringignorecase'] = f[-'string']

      # Returning `string` as default will probably not result in a successful match
      # but will avoid blowing up our entire program if we encounter an unhandled format.
      f.default = f[-'string']

    # Set `host` formats according to system endianness.
    if ORIGIN_OF_SYMMETRY.call == :BE then
      f[-'host16'] = f[-'big16']
      f[-'host32'] = f[-'big32']
    else
      f[-'host16'] = f[-'little16']
      f[-'host32'] = f[-'little32']
    end

  }

  # Map of `shared-mime-info` XML Element names to our generic category names.
  FDO_ELEMENT_CATEGORY = {
    :magic => :content_match,
    :match => :content_match,
    :alias => :family_tree,
    :comment => :textual_metadata,
    :"sub-child-of" => :family_tree,
    :"generic-icon" => :host_metadata,
    :glob => :pathname_match,
  }

  # `MrMIME::new` will take any of these keys as keyword arguments
  # whose value will override the default defined in this Hash.
  DEFAULT_LOADS = {
    :textual_metadata => false,
    :host_metadata => false,
    :pathname_match => true,
    :content_match => true,
    :family_tree => true,
  }

  # You shouldn't abuse the power of the Solid.
  def skips
    @skips ||= self.class::DEFAULT_LOADS.keep_if { |k,v| v == false }.keys.to_set
  end

  def initialize(**kwargs)
    # Per the `Ox::Sax` dox:
    # "Initializing `line` attribute in the initializer will cause that variable to
    #    be updated before each callback with the XML line number.
    #  The same is true for the `column` attribute, but it will be updated with
    #    the column in the XML file that is the start of the element or node just read.
    #  `@pos`, if defined, will hold the number of bytes from the start of the document."
    #@pos = nil
    #@line = nil
    #@column = nil

    # We receive separate events for Elements and Attributes, so we need to keep track of
    # the current Element to know what to do with Attributes since we can't rely on Attribute
    # names to be unique. For example, `shared-mime-info` has an attribute `type` on
    # `<mime-type>`, `<alias>`, `<match>`, and `<sub-class-of>`.
    @parse_stack = Array.new

    # We need a separate stack and a flag boolean for building content-match structures since the source XML
    # represents OR and AND byte-sequence relationships as sibling and child Elements respectively, e.g.
    # <magic><match1><match2/><match3/></match1><match4/></magic> => [m1 AND m2] OR [m1 AND m3], OR [m4].
    @i_can_haz_magic = true

    # Allow the user to control the conditions on which we ignore data from the source XML.
    @skips = self.class::DEFAULT_LOADS.merge(kwargs.slice(*self.class::DEFAULT_LOADS.keys)).keep_if { |k,v|
      v == false
    }.keys.to_set

    # Here's where I would put a call to `super()` a.k.a `Ox::Sax#initialize` — IF IT HAD ONE
  end

  def cyo
    @cyo ||= ::CHECKING::YOU::OUT::from_ietf_media_type(@media_type)
  end


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

  def start_element(name)
    @parse_stack.push(name)
    return if self.skips.include?(name)
    case name
    when :"mime-type"
      @media_type = nil
      @cyo = nil
    when :match
      # Mark any newly-added Sequence as eligible for a full match candidate.
      @i_can_haz_magic = true
      @weighted_action.append(::CHECKING::YOU::OUT::SequenceCat.new)
    when :magic
      @weighted_action = ::CHECKING::YOU::OUT::CatSequence.new
    when :"magic-deleteall"
      # TODO
    when :"glob-deleteall"
      # TODO
    when :treemagic
      # TODO
    when :acronym
      # TODO
    when :"expanded-acronym"
      # TODO
    end
  end

  def attr_value(attr_name, value)
    return if self.skips.include?(@parse_stack.last)
    case [@parse_stack.last, attr_name]
    in :"mime-type", :type
      @media_type = value.as_s
    in :match, :type
      # There's no way to avoid a String allocation in `Ox::Sax::Value#as_s` rn,
      # pending C extension API for interned Strings prolly some time in Ruby 3.x.
      @weighted_action.last.format = FDO_MAGIC_FORMATS[value.as_s]
    in :match, :value
      @weighted_action.last.cat = value.as_s
    in :match, :offset
      @weighted_action.last.boundary = value.as_s
    in :match, :mask
      # The number to AND the value in the file with before comparing it to `value'.
      # Masks for numerical types can be any number, while masks for strings must be in base 16, and start with 0x.
      @weighted_action.last.mask = BASED_STRING.call(value.as_s)
    in :magic, :priority
      @weighted_action&.weight = value.as_i
    in :alias, :type
      self.cyo.add_aka(::CHECKING::YOU::IN::from_ietf_media_type(value.as_s))
    in :"sub-class-of", :type
      self.cyo.add_parent(::CHECKING::YOU::OUT::from_ietf_media_type(value.as_s))
    in :glob, :pattern
      # TODO: Make this less fragile. It assumes all`<glob>` patterns are of the form `*.ext` (they are)
      self.cyo.add_postfix(value.as_s.delete_prefix!(-'*.')||value.as_s)
    in :"root-XML", :namespaceURI
      # TODO
    in :"root-XML", :localName
      # TODO
    else
      # Unsupported attribute encountered.
      # The new pattern matching syntax will raise `NoMatchingPatternError` here without this `else`.
    end
  end

  def text(element_text)
    return if self.skips.include?(@parse_stack.last)
    case @parse_stack.last
    when :comment
      self.cyo.description = element_text
    end
  end

  def end_element(name)
    raise Exception.new('Parse stack element mismatch') unless @parse_stack.pop == name
    return if self.skips.include?(@parse_stack.last)
    case name
    when :"mime-type"
      @media_type = nil
      @cyo = nil
    when :match
      # The Sequence stack represents a complete match once we start popping Sequences from it.
      self.cyo.add_content_match(@weighted_action.dup) if @i_can_haz_magic
      # Mark any remaining partial Sequences as ineligible to be a full match candidate,
      # e.g. if we had a stack of [<match1/><match2/><match3/>] we would want to add a
      # candidate [m1, m2, m3] but not the partials [m1, m2] or [m1] as we clear out the stack.
      @i_can_haz_magic = false
      @weighted_action.pop
    when :magic
      @weighted_action.clear
    end
  end

  def open(path, **kwargs)
    # Use the block form of `IO::open` so the file handle is implicitly closed after we leave this scope.
    # Per Ruby's `IO` module docs:
    # "With no associated block, `::open` is a synonym for `::new`.  If the optional code block is given,
    #  it will be passed the opened file as an argument and the File object will automatically be closed
    #  when the block terminates.  The value of the block will be returned from `::open`."
    File.open(path, File::Constants::RDONLY) { |mime_xml|

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
      mime_xml.advise(:sequential)

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
      #
      # TOD0: Probably String allocation gainz to be had inside Ox's C extension once the API is available:
      # https://bugs.ruby-lang.org/issues/13381
      # https://bugs.ruby-lang.org/issues/16029
      # e.g. https://github.com/msgpack/msgpack-ruby/pull/196
      Ox.sax_parse(
        self,                     # Instance of a class that responds to `Ox::Sax`'s callback messages.
        mime_xml,                 # IO stream or String of XML to parse. Won't close File handles automatically.
        **{
          convert_special: true,  # [boolean] Convert encoded entities back to their unencoded form, e.g. `"&lt"` to `"<"`.
          skip: :skip_off,        # [:skip_none|:skip_return|:skip_white|:skip_off] (from Element text/value) Strip CRs, whitespace, or nothing.
          smart: false,           # [boolean] Toggle Ox's built-in hints for HTML parsing: https://github.com/ohler55/ox/blob/master/ext/ox/sax_hint.c
          strip_namespace: nil,   # [nil|String|true|false] (from Element names) Strip no namespaces, all namespaces, or a specific namespace.
          symbolize: true,        # [boolean] Fill callback method `name` arguments with Symbols instead of with Strings.
        }.update(kwargs),
      )
    }
  end
end

