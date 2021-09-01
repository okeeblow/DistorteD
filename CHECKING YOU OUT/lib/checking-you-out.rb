require(-'pathname') unless defined?(::Pathname)

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
  def self.OUT(unknown_identifier)
    case unknown_identifier
    when ::Pathname
      ::CHECKING::YOU::OUT::from_pathname(unknown_identifier)
    when ::String
      case
      when unknown_identifier.count(-?/) == 1 then  # TODO: Additional String validation here.
        ::CHECKING::YOU::OUT::from_ietf_media_type(unknown_identifier)
      when unknown_identifier.start_with?(-?.) && unknown_identifier.count(-?.) == 1 then
        ::CHECKING::YOU::OUT::from_postfix(unknown_identifier)
      else
        ::CHECKING::YOU::OUT::from_pathname(unknown_identifier)
      end
    when ::CHECKING::YOU::IN
      unknown_identifier.out
    end
  end
end
