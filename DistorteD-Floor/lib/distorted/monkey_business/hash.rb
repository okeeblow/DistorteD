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
  
  # https://github.com/dam13n/ruby-bury/blob/master/hash.rb
  # This is not packaged as a Gem or I'd be using it instead of including my own.
  def bury(*args)
    if args.count < 2
      raise ArgumentError.new('2 or more arguments required')
    elsif args.count == 2
      self[args[0]] = args[1]
    else
      arg = args.shift
      self[arg] = {} unless self[arg]
      self[arg].bury(*args) unless args.empty?
    end
    self
  end

end
