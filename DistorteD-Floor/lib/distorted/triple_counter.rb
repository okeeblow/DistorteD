TripleCounter = Struct.new(:major, :minor, :micro) do
  attr_reader :major, :minor, :micro

  # Include a catch-all so we can splat Array-generating functions
  # into TripleCounter.new(), e.g. Ruby/GStreamer's library version:
  #   irb> require 'gst'
  #   => true
  #   irb> Gst.version
  #   => [1, 19, 0, 1]
  def initialize(major = 0, minor = 0, micro = 0, *_)
    @major = major
    @minor = minor
    @micro = micro
    super(major, minor, micro)  # Intentionally not passing our splat to `super`
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
