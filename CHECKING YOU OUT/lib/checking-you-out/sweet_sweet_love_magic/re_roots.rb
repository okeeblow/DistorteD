require(-'ox') unless defined?(::Ox)

# Components to discover XML documents' root Element name and namespace
# and to match those values to `shared-mime-info`'s `<root-XML>` tags.
module ::CHECKING::YOU::OUT::SweetSweet♥Magic


  # Parse unknown XML files to extract their `xmlns` and their `localName`.
  Namescapes = ::Class::new(::Ox::Sax) do

    # Attribute name for XML NameSpace declarations: https://www.w3.org/TR/xml-names/#ns-decl
    self::XMLNS = -'xmlns'

    # Don't allocate an output structure until we have to.
    def re_roots;   @re_roots ||= ::CHECKING::YOU::OUT::SweetSweet♥Magic::ReRoots::new; end
    def re_roots?; !@re_roots.nil?; end

    # The two values we want are the name of the document's root element, and an attribute of the root element,
    # e.g. a `application/mathml+xml` having root element+attributes `<math xmlns="http://www.w3.org/1998/Math/MathML">`.
    #
    # "localName" means specifically the part of the root Element name minus any namespace prefix:
    # - https://www.w3.org/TR/xml-names/#dt-NSDecl
    # - https://www.w3.org/TR/xml-names/#dt-NSName
    # - https://www.w3.org/TR/xml-names/#dt-localname
    def start_element(name)
      # Our need for only the root Element means we can raise `::StopIteration` and bail out early
      # if we ever call `start_element` twice no matter what element name is represented in those calls.
      raise ::StopIteration unless @re_roots&.localname.nil?
      if name.to_s.include?(-?:) then
        # A namespaced root Element can refer to a namespace prefix defined as an attribute of that same Element.
        # Per https://www.w3.org/TR/xml-names/#scoping  —
        #
        # "The scope of a namespace declaration declaring a prefix extends from the beginning of
        #  the start-tag in which it appears to the end of the corresponding end-tag,
        #  excluding the scope of any inner declarations with the same NSAttName part.
        #  In the case of an empty tag, the scope is the tag itself.
        #
        #  Such a namespace declaration applies to all element and attribute names within its scope
        #  whose prefix matches that specified in the declaration."
        name.split(-?:, 2).tap { |ns_prefix, attr_name|
          # Note how a namespaced Element is `"#{ns_prefix}:element"` but the attribute
          # which *defines* that prefix will be `"xmlns:#{ns_prefix}".
          self.re_roots.localname = -attr_name
          # If there are multiple `"xmlns:#{ns_prefix}" namespace declarations,
          # we should try to use the one matching the prefix of this root Element.
          @root_ns_prefix = -ns_prefix
        }
      else
        # The root element is not namespaced, so the whole thing is the `localName`.
        self.re_roots.localname = -name
      end
    end

    # Any namespace declaration(s) we care about will be attributes of the root Element.
    # https://en.wikipedia.org/wiki/XML_namespace
    def attr(name, attr_value)
      return if @re_roots.nil?  # Skip the attributes of an XML prolog.

      if name.to_s.eql?(self::class::XMLNS) then
        # https://www.w3.org/TR/xml-names/#dt-defaultNS
        self.re_roots.namespace = -attr_value
      elsif name.to_s.include?(-?:) then
        name.to_s.split(-?:, 2).tap { |attr_name, ns_prefix|
          # Note how a namespaced Element is `"#{ns_prefix}:element"` but the attribute
          # which *defines* that prefix will be `"xmlns:#{ns_prefix}".
          self.re_roots.namespace = -attr_value if (
            # We will always take the first namespace we see (when `#namespace.nil?`),
            # but will override it with any namespace whose prefix was used on the root Element.
            self.re_roots.namespace.nil? or ns_prefix.eql?(@root_ns_prefix)
          )
        }
      end
    end

    # We can also bail out early at the end of any Element, root or otherwise.
    def end_element(name); raise ::StopIteration; end

  end  # Namescapes


  # "`<root-XML>` elements have `namespaceURI` and `localName` attributes.
  #  If a file is identified as being an XML file, these rules allow a more specific MIME type to be chosen
  #  based on the namespace and localname of the document element.
  # 
  #  If `localName` is present but empty then the document element may have any name,
  #  but the namespace must still match."
  ReRoots = ::Struct::new(:namespace, :localname) do

    def self.from_pathname(otra)
      # We only want to test extant regular files.
      return unless otra.is_a?(::Pathname)
      return unless otra.file?

      # `otra` file descriptor will be closed after we leave the block scope.
      otra.open(mode=::File::Constants::RDONLY) do |open_my_gate|

        # Tell the filesystem to expect the way `::Ox::Sax` reads files.
        open_my_gate.advise(:sequential)

        # This `from_pathname` will always return an `IVar` from our `::Ox::Sax` subclass instance,
        # not the instance itself. If this is not an XML document, the result will be `nil`.
        Namescapes::new.yield_self {
          begin
            # http://www.ohler.com/ox/Ox.html#method-c-sax_parse
            # We must not `strip_namespace` because it will remove part of a namespaced-root-Element-name we actually want.
            ::Ox::sax_parse(
              _1,
              open_my_gate,
              convert_special: true,   # [boolean] Convert encoded entities back to their unencoded form, e.g. `"&lt"` to `"<"`.
              skip: :skip_off,         # [:skip_none|:skip_return|:skip_white|:skip_off] (from Element text/value) Strip CRs, whitespace, or nothing.
              smart: false,            # [boolean] Toggle Ox's built-in hints for HTML parsing: https://github.com/ohler55/ox/blob/master/ext/ox/sax_hint.c
              strip_namespace: false,  # [nil|String|true|false] (from Element names) Strip no namespaces, all namespaces, or a specific namespace.
              symbolize: false,        # [boolean] Fill callback method `name` arguments with Symbols instead of with Strings.
            )
          rescue ::StopIteration      # Raised by our parser instance as soon as it has seen the all the attributes of the first Element.
          rescue ::Ox::ParseError     # Raised by `::Ox::sax_parse` if the file is malformed XML.
          ensure return _1.re_roots? ? _1.re_roots.freeze : nil
          end
        }
      end
    end  # def self.from_pathname

    def empty?; self[:namespace].nil? and self[:localname].nil?; end

    def clear; self[:namespace], self[:localname] = nil; end


  end  # ReRoots
end
