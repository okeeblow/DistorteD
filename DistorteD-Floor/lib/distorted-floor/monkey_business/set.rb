# Override Set.to_h? to complement Ruby::YAML's Set implementation,
# where the YAML Set syntax returns a Hash with all-nil values,
# at least without some decorator sugar in the YAML itself:
# https://rhnh.net/2011/01/31/yaml-tutorial/
#
# Since Set is implemented using a Hash internally I think it makes
# more sense for Set.to_h to return a Hash with all-nil values
# with keys matching the contents of the original Set.
class Set
  def to_h
    Hash[self.map { |s| [s, nil] }]
  end
end
