require(-'pathname') unless defined?(::Pathname)

# Used for URI-scheme parsing instead of the Ruby stdlib `URI` module.
require(-'addressable') unless defined?(::Addressable)

# Silence warning for Ractor use in Ruby 3.0.
# See https://ruby-doc.org/core/Warning.html#method-c-5B-5D for more.
# TODO: Remove this when Ractors are "stable".
Warning[:experimental] = false


class CHECKING; end
require_relative(-'checking-you-out/inner_spirit') unless defined?(::CHECKING::YOU::IN)


# I'm not trying to be an exact clone of `shared-mime-info`, but I think its "Recommended checking order"
# is pretty sane: https://specifications.freedesktop.org/shared-mime-info-spec/latest/
#
# In addition to the above, CYO() supports IETF-style Media Type strings like "application/xhtml+xml"
# and supports `stat`-less testing of `.extname`-style Strings.
class CHECKING::YOU
  def self.OUT(unknown_identifier, area_code: ::CHECKING::YOU::IN::DEFAULT_AREA_CODE)
    case unknown_identifier
    when ::Pathname then
      ::CHECKING::YOU::OUT::from_pathname(unknown_identifier, area_code: area_code)
    when ::Addressable::URI then
      ::CHECKING::YOU::OUT::from_uri(unknown_identifier, area_code: area_code)
    when ::String
      # Try parsing the given `String` as a `URI`, based on `::Addressable::URI::scheme`:
      #   irb(main):029:0> ::Addressable::URI::parse("/home/okeeblow").scheme => nil
      #   irb(main):030:0> ::Addressable::URI::parse("").scheme => nil
      #   irb(main):031:0> ::Addressable::URI::parse("HTTPS://WWW.COOLTRAINER.ORG").scheme => "HTTPS"
      uri_match = ::Addressable::URI::parse(unknown_identifier)
      case
      when !uri_match.scheme.nil? then
        ::CHECKING::YOU::OUT::from_uri(uri_match, area_code: area_code)
      when unknown_identifier.count(-?/) == 1 then  # TODO: Additional String validation here.
        ::CHECKING::YOU::OUT::from_ietf_media_type(unknown_identifier, area_code: area_code)
      when unknown_identifier.start_with?(-?.) && unknown_identifier.count(-?.) == 1 then
        ::CHECKING::YOU::OUT::from_postfix(unknown_identifier, area_code: area_code)
      else
        ::CHECKING::YOU::OUT::from_pathname(unknown_identifier, area_code: area_code)
      end
    when ::CHECKING::YOU::IN
      unknown_identifier.out(area_code: area_code)
    end
  end
end
