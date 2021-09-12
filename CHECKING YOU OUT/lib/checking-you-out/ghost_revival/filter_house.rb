# Reusable filter `::Proc`s for CYO type-matching logic,
# e.g. for busting spurious `::Enumerable`s.
module ::CHECKING::YOU::OUT::GHOST_REVIVAL

  # Never return empty `::Enumerable`s.
  # Yielding-self to this proc will `nil`-ify anything that's `:empty?`
  # and will pass any non-`::Enumerable` `::Object`s through.
  POINT_ZERO = ::Ractor.make_shareable(proc { _1.respond_to?(:empty?) ? (_1.empty? ? nil : _1) : _1 })

  # Never return `::Enumerable`s with fewer than two members.
  # Yielding-self to this proc will `nil`-ify anything that's `#size` >= 2
  # and will pass any non-Enumerable Objects through.
  XANADU_OF_TWO = ::Ractor.make_shareable(proc { _1.respond_to?(:size) ? (_1.size >= 2 ? _1 : nil) : _1 })

  # Never return `::Enumerable`s containing only a single member.
  # Return the single member itself, or the entire thing if `#size > 2`.
  ONE_OR_EIGHT = ::Ractor.make_shareable(proc { |huh|
    case
    when huh.nil? then nil
    when huh.respond_to?(:empty?), huh.respond_to?(:first?)
      if huh.empty? then nil
      elsif huh.size == 1 then huh.is_a?(::Hash) ? huh.values.first : huh.first
      else huh
      end
    else huh
    end
  })

end
