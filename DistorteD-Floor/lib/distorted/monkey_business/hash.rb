# https://github.com/dam13n/ruby-bury/blob/master/hash.rb
# This is not packaged as a Gem or I'd be using it instead of including my own.
class Hash
  
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
