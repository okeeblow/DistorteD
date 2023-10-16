require('bundler/setup')
require('test/unit') unless defined?(::Test::Unit)
require_relative('../lib/globeglitter') unless defined?(::GlobeGlitter)

class TestGlobeGlitterFirstResolution < Test::Unit::TestCase

  # ITU-T Rec. X.667 sez —
  #
  # “To compare a pair of UUIDs, the values of the corresponding fields (see 6.1) of each UUID are compared,
  #  in order of significance (see 6.1.2). Two UUIDs are equal if and only if all the corresponding fields are equal.
  #
  #  NOTE 1 — This algorithm for comparing two UUIDs is equivalent to the comparison of the values of
  #           the single integer representations specified in 6.3.
  #  NOTE 2 — This comparison uses the physical fields specified in 6.1.1 not the values listed in 6.1.3
  #           and specified in clause 12 (Time, Clock Sequence, Variant, Version, and Node).
  #
  # A UUID is considered greater than another UUID if it has a larger value for the most significant field in which they differ.
  #
  # In a lexicographical ordering of the hexadecimal representation of UUIDs (see 6.4), a larger UUID shall follow a smaller UUID.”
  def test_itu_t_rec_x667_comparator
    assert_operator(
      ::GlobeGlitter::new("f81d4fae-7dec-11d0-a765-00a0c91e6bf6"),
      :<,
      ::GlobeGlitter::new("f81d4fae-7dec-11d0-a765-00a0c91e6bf7"),
    )
  end

  # Example SQL Server sort from https://bornsql.ca/blog/how-sql-server-stores-data-types-guid/
  def test_microsoft_sql_server_comparator
  end

  def test_time_uuid
    t1 = ::GlobeGlitter::from_time
    t2 = ::GlobeGlitter::from_time
    assert_operator(t1, :<, t2)
  end
end
