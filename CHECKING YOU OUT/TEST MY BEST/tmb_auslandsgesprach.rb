require(-'ox') unless defined?(::Ox)

fdo_mime = ::CHECKING::YOU::IN::GHOST_REVIVAL::SharedMIMEinfo.new(::File.join(
  ::CHECKING::YOU::OUT::GEM_ROOT.call,
  -'mime',
  -'packages',
  -'third-party',
  -'shared-mime-info',
  "#{::CHECKING::YOU::IN::GHOST_REVIVAL::FDO_MIMETYPES_FILENAME}.in",
))

module OnlyOnePackage
  refine ::CHECKING::YOU::IN::GHOST_REVIVAL do
    def discover_fdo_xml; ::Array.new.push(fdo_mime); end
  end
end
using OnlyOnePackage

class IETFTypeChecker < ::Ox::Sax
  def initialize(...)
    @out = Array.new
    @parse_stack = Array.new
  end
  def end_element(name)
    raise Exception.new('Parse stack element mismatch') unless @parse_stack.pop == name
  end
  def start_element(name)
    @parse_stack.push(name)
  end
  def attr_value(attr_name, value)
    case [@parse_stack.last, attr_name]
    in :"mime-type", :type
    @out.append(value.as_s)
    else
    end
  end
  def open(path, **kwargs)
    File.open(path, File::Constants::RDONLY) { |mime_xml|
      mime_xml.advise(:sequential)
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
    @out
  end
end

::CHECKING::YOU::OUT::send(/.*/)
area_code = 'TEST MY BEST'

handler = IETFTypeChecker.new
fdo_types = handler.open(fdo_mime)

# Define a test for every `<mime-type>` element in `shared-mime-info`'s XML
# asserting that CYO's `#to_s` outputs an identical `String` for that type.
TestAuslandsgesprach = fdo_types.each_with_object(Class.new(Test::Unit::TestCase)) { |type, classkey_csupó|
  classkey_csupó.define_method("test_#{type.downcase.gsub(/[\/\-_+\.=;]/, ?_)}_ietf_type_decomposition") {
    # TODO: Fix suffixed types (remove `unless` guard)
    assert_equal(type, ::CHECKING::YOU::OUT::from_ietf_media_type(type, area_code: area_code).to_s) unless type.include?(?+)
    #assert_include(::CHECKING::YOU::OUT::from_ietf_media_type(type).aka.map(&:to_s), type) unless type.include?(?+)
  }
}
