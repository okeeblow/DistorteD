require 'pathname' unless defined? ::Pathname

# Silence warning for pattern matching used in several Modules of this library.
# See https://ruby-doc.org/core-2.7.0/Warning.html#method-c-5B-5D for more.
# TODO: Remove this when our minimum Ruby version is >= 3.0,
# since pattern matching was made non-experimental in https://bugs.ruby-lang.org/issues/17260
Warning[:experimental] = false

require_relative 'checking-you-out/inner_spirit' unless defined? ::CHECKING::YOU::IN


module CHECKING; end
class CHECKING::YOU
  def self.OUT(unknown_identifier)
    case unknown_identifier
    when ::Pathname
      ::CHECKING::YOU::OUT::from_pathname(unknown_identifier)
    when ::String
      case
      when unknown_identifier.start_with?(-?.) && unknown_identifier.count(-?.) == 1
        ::CHECKING::YOU::OUT::from_postfix(unknown_identifier)
      when File.exist?(unknown_identifier)
        ::CHECKING::YOU::OUT::from_pathname(Pathname.new(unknown_identifier))
      when unknown_identifier.count(-?/) == 1
        ::CHECKING::YOU::OUT::from_ietf_media_type(unknown_identifier)
      else
        # TODO: Raise something here? Return an empty (but allocated) Set?
        nil
      end
      # TODO: A String arg could also be a path, an extname with no leading dot,
      # or an entire file stream.
      # Support path Strings that haven't been expanded by a shell.
      # Support fallback attempts if we think an unknown_id is something but get nil.
    when ::CHECKING::YOU::IN
      unknown_identifier.out
    end
  end
end
