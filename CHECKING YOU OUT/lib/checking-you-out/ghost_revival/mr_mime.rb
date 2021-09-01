
require 'ox'


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
class CHECKING::YOU::MrMIME < ::Ox::Sax



  # Turn an arbitrary String into the correctly-based Integer it represents.
  # It would be nice if I could do this directly in `Ox::Sax::Value`.
  # Base-16 Ints can be written as literals in Ruby, e.g.
  # irb> 0xFF
  # => 255
  BASED_STRING = proc {
    # Operate on codepoints to avoid `String` allocation from slicing, e.g. `_1[...1]`
    # would allocate a new two-character `String` before we have chance to dedupe it.
    # The `shared-mime-info` XML is explicitly only in UTF-8, so this is safe.
    #
    # The below is equivalent to:
    # ```case
    # when -s[0..1].downcase == -'0x' then s.to_i(16)
    # when s.chr == -?0 then s.to_i(8)
    # else s.to_i(10)
    # end```
    #
    # …but rewritten to check for first-codepoint `'0'`, then second-codepoint `'x'/'X'`:
    #   irb> ?0.ord => 48
    #   irb> [?X.ord, ?x.ord] => [88, 120]
    #
    # Relies on the fact that `#ord` of a long `String` is the same as `#ord` of its first character:
    #   irb> 'l'.ord => 108
    #   irb> 'lmfao'.ord => 108
    (_1.ord == 48) ?
      ([88, 120].include?(_1.codepoints[1]) ? _1.to_i(16) : _1.to_i(8)) :
      _1.to_i(10)
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
    when :"mime-type" then
      @media_type = String.new if @media_type.nil?
      @cyo = nil
    when :match then
      # Mark any newly-added Sequence as eligible for a full match candidate.
      @i_can_haz_magic = true
      @speedy_cat.append(::CHECKING::YOU::OUT::SequenceCat.new)
    when :magic then
      @speedy_cat = ::CHECKING::YOU::OUT::SpeedyCat.new if @speedy_cat.nil?
    when :"magic-deleteall" then
      # TODO
    when :glob then
      @stick_around = ::CHECKING::YOU::StickAround.new
    when :"glob-deleteall" then
      # TODO
    when :treemagic then
      # TODO
    when :acronym then
      # TODO
    when :"expanded-acronym" then
      # TODO
    end
  end

  def attr_value(attr_name, value)
    return if self.skips.include?(@parse_stack.last)
    # `parse_stack` can be empty here in which case its `#last` will be `nil`.
    # This happens e.g. for the two attributes of the XML declaration '<?xml version="1.0" encoding="UTF-8"?>'.
    #
    # Avoid the `Array` allocation necessary when using pattern matching `case` syntax.
    # I'd still like to refactor this to avoid the redundant `attr_name` `case`s.
    # Maybe a `Hash` of `proc`s?
    case @parse_stack.last
    when :"mime-type" then
      case attr_name
      when :type then @media_type.replace(value.as_s)
      end
    when :match then
      case attr_name
      when :type then @speedy_cat.last.format = FDO_MAGIC_FORMATS[value.as_s]
      when :value then @speedy_cat.last.cat = value.as_s
      when :offset then @speedy_cat.last.boundary = value.as_s
      when :mask then @speedy_cat.last.mask = BASED_STRING.call(value.as_s)
      end
    when :magic then
      case attr_name
      when :priority then @speedy_cat&.weight = value.as_i
      end
    when :alias then
      case attr_name
      when :type then self.cyo.add_aka(::CHECKING::YOU::IN::from_ietf_media_type(value.as_s))
      end
    when :"sub-class-of" then
      case attr_name
      when :type then self.cyo.add_parent(::CHECKING::YOU::OUT::from_ietf_media_type(value.as_s))
      end
    when :glob then
      case attr_name
      when :weight then @stick_around.weight = value.as_i
      when :pattern then @stick_around.replace(value.as_s)
      when :"case-sensitive" then @stick_around.case_sensitive = value.as_bool
      end
    when :"root-XML" then
      #case attr_name
      #when :namespaceURI then  # TODO
      #when :localName then  # TODO
      #end
    end
  end

  def text(element_text)
    return if self.skips.include?(@parse_stack.last)
    case @parse_stack.last
    when :comment then
      self.cyo.description = element_text
    end
  end

  def end_element(name)
    raise Exception.new('Parse stack element mismatch') unless @parse_stack.pop == name
    return if self.skips.include?(@parse_stack.last)
    case name
    when :"mime-type" then
      @media_type.clear
      @cyo = nil
    when :match then
      # The Sequence stack represents a complete match once we start popping Sequences from it,
      # which we can know because every `<match>` stack push sets `@i_can_haz_magic = true`.
      # If there is only a single sub-sequence we can just add that instead of the container.
      self.cyo.add_content_match(
        # Add single-sequences directly instead of adding their container.
        @speedy_cat.one? ?
          # Transfer any non-default `weight` from the container to that single-sequence.
          @speedy_cat.pop.tap { _1.weight = @speedy_cat.weight } :
          # Otherwise go ahead and add a copy of the container while also preparing the
          # local container for a possible next-branch to the `<magic>` tree.
          @speedy_cat.dup.tap { @speedy_cat.pop }
      ) if @i_can_haz_magic
      # Mark any remaining partial Sequences as ineligible to be a full match candidate,
      # e.g. if we had a stack of [<match1/><match2/><match3/>] we would want to add a
      # candidate [m1, m2, m3] but not the partials [m1, m2] or [m1] as we clear out the stack.
      @i_can_haz_magic = false
    when :magic then
      # `SpeedyCat#clear` will unset any non-default `weight` so we can re-use it cleanly.
      @speedy_cat.clear
    when :glob then
      self.cyo.add_pathname_fragment(@stick_around) unless @stick_around.nil?
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
          strip_namespace: true,  # [nil|String|true|false] (from Element names) Strip no namespaces, all namespaces, or a specific namespace.
          symbolize: true,        # [boolean] Fill callback method `name` arguments with Symbols instead of with Strings.
          intern_strings: true,   # [boolean] Intern (freeze and deduplicate) String return values.
        }.update(kwargs),
      )
    }
  end
end

