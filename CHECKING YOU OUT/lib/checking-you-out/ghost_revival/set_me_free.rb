require(-'set') unless defined?(::Set)


module ::CHECKING::YOU::OUT::GHOST_REVIVAL

  # `::Hash` subclass with integrated single-value-to-`Set` upgrading for duplicate keys.
  # Used as the data store for CYO's filename-matching structures.
  # It's defined this way to work around a `defined in a different Ractor` `RuntimeError`.
  SET_ME_FREE = ::Ractor.make_shareable(proc {
    ::Class.new(::Hash).tap {

      # Equivalent to `::Hash#store` for unset keys.
      # Subsequent stores for the same key will result in a `::Set` containing all values.
      _1.define_method(:bury) { |haystack, needle|
        return if haystack.nil? or needle.nil?
        if haystack.instance_of?(::Set) then
          # Use `#instance_of?` instead of `#is_a?` to avoid unrolling a `B4U`.
          haystack.each { |straw| self.bury(straw, needle) }
        elsif self.has_key?(haystack) then
          if self[haystack].is_a?(::Set) then self[haystack].add(needle)
          elsif self[haystack] == needle then next
          else self.store(haystack, ::Set[self.fetch(haystack), needle])
          end
        else
          self.store(haystack, needle)
        end
      }
      # This should also be used for `my_hash[some_key] = some_value`.
      _1.alias_method(:[]=, :bury)

      # Merge another `::Hash`'s contents with `::Set` upgrading.
      _1.define_method(:merge) { |otra|
        otra.each_pair { |haystack, needle|
          self.bury(haystack, needle)
        }
      }

      # Do the reverse of `:bury`, deleting values for given keys.
      _1.define_method(:baleet) { |haystack, needle|
        return if haystack.nil? or needle.nil?
        if haystack.is_a?(::Set) then
          haystack.each { |straw| self.baleet(straw, needle) }
        elsif self.has_key?(haystack) then
          if self[haystack].is_a?(::Set) then
            if self[haystack].one? then
              self.delete(haystack)
            else
              #TOD0: Figure out why these `Set`s are ending up frozen.
              #self[haystack].delete(needle)
              self.store(haystack, ::Set[*self[haystack].reject(&needle.method(:===))])
            end
          elsif self[haystack] == needle then self.delete(haystack)
          end
        end
      }

      # Support retrieving the heaviest `WeightedAction` given a list of weight methods.
      _1.const_set(:LEGENDARY_HEAVY_GLOW, ::Ractor.make_shareable(proc { |action, weights|
        weights.select!.with_object(
          (weights.is_a?(::Hash) ? weights.keys : weights).max.send(action)
        ) { |(weight, _), max| weight.send(action) >= max }
        weights
      }))
      _1.define_method(:push_up) { |*actions|
        self.empty? ? nil
        : actions.each_with_object(self).map(&self.singleton_class.const_get(:LEGENDARY_HEAVY_GLOW))
      }
    }
  })

end  # ::CHECKING::YOU::IN::GHOST_REVIVAL
