require(-'set') unless defined?(::Set)

require_relative(-'stella_sinistra/steel_needle') unless defined?(::CHECKING::YOU::OUT::StellaSinistra::STEEL_NEEDLE)
require_relative(-'stella_sinistra/stick_around') unless defined?(::CHECKING::YOU::OUT::StickAround)

# Filename-matching components.
module ::CHECKING::YOU::OUT::StellaSinistra

  # Add a new filename-match to a specific type.
  def add_pathname_fragment(fragment)
    # Store single-extname "postfix" matches separately from more complex (possibly regexp-like) matches.
    # A "postfix" will be like `"*.jpg"` — representing only a single extname with leading wildcard.
    self.awen(fragment.postfix? ? :@postfixes : :@complexes, fragment)
  end
  attr_reader(:postfixes, :complexes)

  # Returns the "primary" file extension for this type.
  # For now we'll assume the `#first` extname is the primary.
  def extname
    case @postfixes
    when ::NilClass then nil
    when ::Symbol then @postfixes.to_s
    when ::String then @postfixes
    when ::Set then @postfixes.first
    else nil
    end&.delete_prefix(-?*)
  end

  # Unset the IVars for Postfixes and Complexes.
  def clear_pathname_fragments
    self.remove_instance_variable(:@postfixes)
    self.remove_instance_variable(:@complexes)
  end

end
