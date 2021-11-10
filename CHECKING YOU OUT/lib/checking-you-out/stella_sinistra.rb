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

  # Return the path fragments of just this type, or a combination of all its' parents' fragments.
  def postfixes(include_parents=false)
    include_parents ? self.thridneedle(:@postfixes, :postfixes) : self.instance_variable_get(:@postfixes)
  end
  def complexes(include_parents=false)
    include_parents ? self.thridneedle(:@complexes, :complexes) : self.instance_variable_get(:@complexes)
  end

  # Returns the "primary" file extension for this type. Per the `shared-mime-info` docs:
  # "The first `glob` element represents the "main" extension for the file type. While this doesn't affect
  #  the mimetype matching algorithm, this information can be useful when a single main extension is needed for a mimetype,
  #  for instance so that applications can choose an appropriate extension when saving a file."
  def extname
    case self.postfixes
    in ::NilClass then nil
    in ::Symbol => extname then extname.to_s
    in ::String => extname then extname
    in ::Set => postfixes then postfixes.first.to_s
    else nil
    end&.delete_prefix(-?*)&.-@
  end

  # Unset the IVars for Postfixes and Complexes.
  def clear_pathname_fragments(include_super=false)
    self.remove_instance_variable(:@postfixes)
    self.remove_instance_variable(:@complexes)
    if include_super then
      case self.parents
      when ::NilClass then  # No-op
      when ::CHECKING::YOU::OUT then
        self.parents.clear_pathname_fragments(include_super)
      when ::Set then
        self.parents.map(&:out).each {
          _1.clear_pathname_fragments(include_super)
        }
      end
    end
  end

end
