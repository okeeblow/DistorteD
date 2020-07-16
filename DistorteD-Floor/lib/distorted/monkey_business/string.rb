class String
  # https://stackoverflow.com/a/22586646
  def map
    size.times.with_object('') {|i,s| s << yield(self[i])}
  end
end
