require 'set'

class Hash

  # Complement Ruby::YAML behavior, where usage of Set syntax
  # returns a Hash with all-nil values.
  # Calling :to_set on a Hash with all-nil values should return
  # a Set of the Hash's keys.
  this_old_set = instance_method(:to_set)
  define_method(:to_set) do
    if self.values.all?{ |v| v.nil? }
      self.keys.to_set
    else
      this_old_set.bind(self).()
    end
  end
  
end
