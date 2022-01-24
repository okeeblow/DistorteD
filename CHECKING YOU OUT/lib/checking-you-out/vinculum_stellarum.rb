require(-'set') unless defined?(::Set)

# Used for URI-scheme parsing instead of the Ruby stdlib `URI` module.
require(-'addressable') unless defined?(::Addressable)

require_relative(-'vinculum_stellarum/irregular_nation') unless defined?(::CHECKING::YOU::OUT::VinculumStellarum::IRREGULAR_NATION)
require_relative(-'vinculum_stellarum/steel_needle') unless defined?(::CHECKING::YOU::OUT::VinculumStellarum::STEEL_NEEDLE)
require_relative(-'vinculum_stellarum/astraia_no_soubei') unless defined?(::CHECKING::YOU::OUT::ASTRAIAの双皿)
require_relative(-'vinculum_stellarum/stella_sinistra') unless defined?(::CHECKING::YOU::OUT::StellaSinistra)
require_relative(-'vinculum_stellarum/deus_dextera') unless defined?(::CHECKING::YOU::OUT::DeusDextera)


# Filename-matching class-level components.
module ::CHECKING::YOU::OUT::VinculumStellarum

  # For URIs we will match a `x-scheme-handler/#{scheme}` type.
  #
  # Ruby's stdlib `URI` module (at least as of MRI 3.0) supports RFC 2396 and RFC 3986
  # but not RFC 3987 (IRIs) or RFC 6570 (URI Templates):
  # - https://datatracker.ietf.org/doc/html/rfc2396
  # - https://datatracker.ietf.org/doc/html/rfc3986
  # - https://lists.w3.org/Archives/Public/w3c-dist-auth/2005OctDec/0494.html
  # - https://datatracker.ietf.org/doc/html/rfc3987
  # - https://datatracker.ietf.org/doc/html/rfc6570
  # - https://github.com/sporkmonger/addressable
  #
  # Even though we usually only need the URI scheme, I'm going to pull in the `addressable` Gem
  # because the `stdlib` `URI` module fails to match at all if there are non-ASCII characters in the given URI:
  #   irb> "file:///home/okeeblow/あああ.txt".match(URI::RFC3986_Parser::RFC3986_URI) => nil
  #   irb> ::Addressable::URI::parse("file:///home/okeeblow/あああ.txt").scheme => "file"
  #
  # Example: `irb> CYO::from_uri("HTTPS://WWW.COOLTRAINER.ORG").to_s => "x-scheme-handler/https"`
  def from_uri(
    otra,
    area_code: ::CHECKING::YOU::OUT::DEFAULT_AREA_CODE,
    receiver: ::Ractor::current
  )
    self.[](
      case otra
      when ::String then
        uri_match = ::Addressable::URI::parse(otra)
        uri_match.scheme.nil? ? otra : uri_match
      when ::Addressable::URI then otra
      else nil
      end,
      area_code:,
      receiver:,
    )
  end

end


# Instance-level filename-matching components, e.g. `*.jpg` => `#<CYO image/jpeg>`.
module ::CHECKING::YOU::OUT::VotumStellarum

  # Add a new filename-match to a specific type.
  def add_pathname_fragment(fragment)
    # Store single-extname "postfix" matches separately from more complex (possibly regexp-like) matches.
    # A "postfix" will be like `"*.jpg"` — representing only a single extname with leading wildcard.
    self.awen(fragment.sinistar? ? :@sinistar : :@astraia, fragment)
  end

  # Return the path fragments of just this type, or a combination of all its' parents' fragments.
  def sinistar(include_parents=false)
    include_parents ? self.thridneedle(:@sinistar, :sinistar) : self.instance_variable_get(:@sinistar)
  end
  def astraia(include_parents=false)
    include_parents ? self.thridneedle(:@astraia, :astraia) : self.instance_variable_get(:@astraia)
  end

  # Returns the "primary" file extension for this type. Per the `shared-mime-info` docs:
  # "The first `glob` element represents the "main" extension for the file type. While this doesn't affect
  #  the mimetype matching algorithm, this information can be useful when a single main extension is needed for a mimetype,
  #  for instance so that applications can choose an appropriate extension when saving a file."
  def extname
    case self.sinistar
    in ::NilClass then nil
    in ::Symbol => extname then extname.to_s
    in ::String => extname then extname
    in ::Set => sinistar then sinistar.first.to_s
    else nil
    end&.delete_prefix(-?*)&.yield_self {
      # Match the leading dot (`.`) behavior of `::File::extname`:
      #   irb> ::File::extname('hello.jpg') => ".jpg"
      _1.start_with?(-?.) ? _1 : (
        (_1.frozen? ? _1.dup : _1).insert(0, -?.)
      )
    }&.-@
  end

  # Unset the IVars for Postfixes and Globs.
  def clear_pathname_fragments(include_super=false)
    self.remove_instance_variable(:@sinistar) if self.instance_variable_defined?(:@sinistar)
    self.remove_instance_variable(:@astraia) if self.instance_variable_defined?(:@astraia)
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
