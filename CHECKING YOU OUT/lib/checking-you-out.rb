require 'pathname' unless defined? ::Pathname

# Silence warning for pattern matching used in several Modules of this library.
# See https://ruby-doc.org/core-2.7.0/Warning.html#method-c-5B-5D for more.
# TODO: Remove this when our minimum Ruby version is >= 3.0,
# since pattern matching was made non-experimental in https://bugs.ruby-lang.org/issues/17260
Warning[:experimental] = false


class CHECKING; end
require_relative 'checking-you-out/inner_spirit' unless defined? ::CHECKING::YOU::IN


# I'm not trying to be an exact clone of `shared-mime-info`, but I think its "Recommended checking order"
# is pretty sane: https://specifications.freedesktop.org/shared-mime-info-spec/latest/
#
# In addition to the above, CYO() supports IETF-style Media Type strings like "application/xhtml+xml"
# and supports `stat`-less testing of `.extname`-style Strings.
class CHECKING::YOU
  def self.OUT(unknown_identifier, so_deep: true)
    case unknown_identifier
    when ::Pathname
      TEST_EXTANT_PATHNAME.call(unknown_identifier)
    when ::String
      case
      when unknown_identifier.count(-?/) == 1 then  # TODO: Additional String validation here.
        ::CHECKING::YOU::OUT::from_ietf_media_type(unknown_identifier)
      when unknown_identifier.start_with?(-?.) && unknown_identifier.count(-?.) == 1 then
        ::CHECKING::YOU::OUT::from_pathname(unknown_identifier)
      else
        if File::exist?(File::expand_path(unknown_identifier)) and so_deep then
          TEST_EXTANT_PATHNAME.call(Pathname.new(File::expand_path(unknown_identifier)))
        else
          LEGENDARY_HEAVY_GLOW.call(::CHECKING::YOU::OUT::from_glob(unknown_identifier), :weight) || ::CHECKING::YOU::OUT::from_postfix(unknown_identifier)
        end
      end
    when ::CHECKING::YOU::IN
      unknown_identifier.out
    end
  end
end
