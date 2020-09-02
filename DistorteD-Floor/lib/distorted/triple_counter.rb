TripleCounter = Struct.new(:major, :minor, :micro) do
  attr_reader :major, :minor, :micro

  def initialize(major = 0, minor = 0, micro = 0)
    @major = major
    @minor = minor
    @micro = micro
  end

  def to_s
    [major, minor, micro].join('.'.freeze)
  end

  def ==(otra)
    major == otra.major && minor == otra.minor
  end

  def ===(otra)
    all_operator(otra, :==)
  end

  def >=(otra)
    all_operator(otra, :>=)
  end

  def <=(otra)
    all_operator(otra, :<=)
  end

  def >(otra)
    all_operator(otra, :>)
  end

  def <(otra)
    all_operator(otra, :<)
  end

  def to_array
    [major, minor, micro]
  end

  def all_operator(otra, operator)
    to_array.zip(otra.to_array).all?{|us, otra| us.send(operator, otra)}
  end
end
