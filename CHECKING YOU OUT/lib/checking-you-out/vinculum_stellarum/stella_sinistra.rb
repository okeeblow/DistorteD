require_relative(-'deus_dextera') unless defined?(::CHECKING::YOU::OUT::DeusDextera)

# Custom `::Array` subclass to represent multiple file extensions simultaneously,
# e.g. `*.tar.bz2` => `StellaSinistra['bz2', 'tar']`
::CHECKING::YOU::OUT::StellaSinistra = ::Class::new(::Array) do

  include(::CHECKING::YOU::OUT::WeightedAction)

  # Convert a `*.extname`-style `::String` glob into an instance of us.
  # The most significant `extname` will be our `#first` member,
  # so we can be easily splatted into a `#dig` in another container.
  def self.from_string(otra)
    raise(
      ::ArgumentError,
      'string format must be `*(.extname)+`, e.g. `*.jpg` or `*.tar.bz2`'
    ) unless otra.start_with?(-'*.') and otra.count(-?*).eql?(1)
    self[
      *otra.delete_prefix(-'*.').split(?.).reverse!.map!(
        &::CHECKING::YOU::OUT::DeusDextera::method(:new)
      ).map!(&:-@)
    ]
  end

  # Ruby language convention for conversion of an unknown other.
  def self.try_convert(otra) = otra.is_a?(::String) ? self.from_string(otra) : super(otra)

  # Convert our member extnames back into a `::String` glob,
  # e.g. `StellaSinistra[bz2, tar]` => `*.tar.bz2`.
  def to_glob
    self.reverse_each.with_object(::String::new(?*)) {
      # NOTE: This expects all of our members to conform to a `*.extname` style
      #       so `::File::extname` returns just the `.whatever`.
      #       `DeusDextera::new` and `#replace` take care of this.
      _2.insert(-1, ::File::extname(_1))
    }
  end

  # Explicit…
  alias_method(:to_s, :to_glob)
  # …and implicit `::String` conversion.
  alias_method(:to_str, :to_glob)

  # We represent a right-hand-side multi-`extname`.
  def sinistar? = true

  # Always return a new instance so we don't get caught out with a `#clear` by reference.
  def sinistar  = self.dup

end  # StellaSinistra
