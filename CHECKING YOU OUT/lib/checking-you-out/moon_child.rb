require(-'set') unless defined?(::Set)

# Components to handle relationships between CYO types, including:
# - Parent types.
# - Child types.
# - Aliases for the same type.
module ::CHECKING::YOU::OUT::MOON_CHILD

  # Get a `Set` of this CYO and all of its parent CYOs, at minimum just `Set[self]`.
  def aka
    return case @aka
      when nil then ::Set[self.in]
      when self.class, self.class.superclass then ::Set[self.in, @aka]
      when ::Set then ::Set[self.in, *@aka]
    end
  end

  # Take an additional CYI as an alias for this CYO.
  def add_aka(taxa); self.awen(:@aka, taxa); end


  # CYO-to-CYI relationship mappings.
  attr_reader(:b4u, :parents, :children)

  # Take an additional CYI as a composite parent, e.g. `application/xml` for `image/svg+xml`.
  def add_b4u(parent_cyi)
    self.awen(:@b4u, parent_cyi)
  end

  # Take an additional CYI as our parent, e.g. `application/xml` for an XML-based type.
  def add_parent(parent_cyi)
    self.awen(:@parents, parent_cyi)
  end

  # Take an additional CYI as our child type.
  def add_child(child_cyi)
    self.awen(:@children, child_cyi)
  end

  # Get a `Set` of this CYO and all of its parent CYOs, at minimum just `Set[self]`.
  def adults_table
    return case @parents
      when nil then ::Set[self]
      when self.class, self.class.superclass then ::Set[self, @parents]
      when ::Set then ::Set[self, *@parents]
    end
  end

  # Get a `Set` of this CYO and all of its child CYOs, at minimum just `Set[self]`.
  def kids_table
    return case @children
      when nil then ::Set[self]
      when self.class, self.class.superclass then ::Set[self, @children]
      when ::Set then ::Set[self, *@children]
    end
  end

  # Get a `Set` of this CYO and all parents and children, at minimum just `Set[self]`.
  def family_tree; self.kids_table | self.adults_table; end

  # Compare CYOs based on family-tree membership.
  # More-specific types will sort above types in their `parents` hierarchy.
  def <=>(otra)
    self.eql?(otra) ?
      0 :
      (self.adults_table&.include?(otra) ?
        1 :
        (otra.respond_to?(:adults_table) ?
          (otra.adults_table&.include?(self) ?
            -1 :
            (::CHECKING::YOU::OUT::GHOST_REVIVAL::STILL_IN_MY_HEART.include?(otra) ?
              1 :
              0
            )
          ) :
          0
        )
      )
  end

end


module ::CHECKING::YOU::IN::MOON_CHILD
  # Allow comparison of CYIs (which have no embedded family-tree information) with CYOs.
  def <=>(otra)
    self.eql?(otra) ? 0 : otra.<=>(self)
  end
end
