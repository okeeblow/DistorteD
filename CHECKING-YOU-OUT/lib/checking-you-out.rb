
require_relative 'checking-you-out/inner_spirit' unless defined? ::CHECKING::YOU::IN


module CHECKING; end
class CHECKING::YOU
  def self.OUT(unknown_identifier)
    case unknown_identifier
    when Pathname
      ::CHECKING::YOU::OUT::from_pathname(unknown_identifier)
    when String
      case
      when unknown_identifier.start_with?('.'.freeze) && unknown_identifier.count('.'.freeze) == 1
        ::CHECKING::YOU::OUT::from_postfix(unknown_identifier)
      when File.exist?(unknown_identifier)
        ::CHECKING::YOU::OUT::from_pathname(Pathname.new(unknown_identifier))
      end
      # TODO: A String arg could also be a path, an extname with no leading dot,
      # or an entire file stream.
      # Support path Strings that haven't been expanded by a shell.
      # Support fallback attempts if we think an unknown_id is something but get nil.
    when ::CHECKING::YOU::IN
      ::CHECKING::YOU::OUT::new(unknown_identifier)
    end
  end
end
