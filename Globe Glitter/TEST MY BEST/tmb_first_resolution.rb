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
    # Adapted from the first of four examples in Raymond Chen's
    # “How many ways are there to sort GUIDs? How much time do you have?”
    # https://devblogs.microsoft.com/oldnewthing/20190426-00/?p=102450
    sorted_bytes = [
      ::GlobeGlitter::new([0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]),
      ::GlobeGlitter::new([0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]),
      ::GlobeGlitter::new([0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]),
      ::GlobeGlitter::new([0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]),
      ::GlobeGlitter::new([0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]),
      ::GlobeGlitter::new([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]),
      ::GlobeGlitter::new([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]),
      ::GlobeGlitter::new([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]),
      ::GlobeGlitter::new([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]),
      ::GlobeGlitter::new([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]),
      ::GlobeGlitter::new([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]),
      ::GlobeGlitter::new([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF]),
      ::GlobeGlitter::new([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF]),
      ::GlobeGlitter::new([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF]),
      ::GlobeGlitter::new([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF]),
      ::GlobeGlitter::new([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00]),
    ]
    sorted_uuid_strings = [
      ::GlobeGlitter::new("00ffffff-ffff-ffff-ffff-ffffffffffff"),
      ::GlobeGlitter::new("ff00ffff-ffff-ffff-ffff-ffffffffffff"),
      ::GlobeGlitter::new("ffff00ff-ffff-ffff-ffff-ffffffffffff"),
      ::GlobeGlitter::new("ffffff00-ffff-ffff-ffff-ffffffffffff"),
      ::GlobeGlitter::new("ffffffff-00ff-ffff-ffff-ffffffffffff"),
      ::GlobeGlitter::new("ffffffff-ff00-ffff-ffff-ffffffffffff"),
      ::GlobeGlitter::new("ffffffff-ffff-00ff-ffff-ffffffffffff"),
      ::GlobeGlitter::new("ffffffff-ffff-ff00-ffff-ffffffffffff"),
      ::GlobeGlitter::new("ffffffff-ffff-ffff-00ff-ffffffffffff"),
      ::GlobeGlitter::new("ffffffff-ffff-ffff-ff00-ffffffffffff"),
      ::GlobeGlitter::new("ffffffff-ffff-ffff-ffff-00ffffffffff"),
      ::GlobeGlitter::new("ffffffff-ffff-ffff-ffff-ff00ffffffff"),
      ::GlobeGlitter::new("ffffffff-ffff-ffff-ffff-ffff00ffffff"),
      ::GlobeGlitter::new("ffffffff-ffff-ffff-ffff-ffffff00ffff"),
      ::GlobeGlitter::new("ffffffff-ffff-ffff-ffff-ffffffff00ff"),
      ::GlobeGlitter::new("ffffffff-ffff-ffff-ffff-ffffffffff00"),
    ]
    sorted_guid_strings = [
      ::GlobeGlitter::new("{FFFFFF00-FFFF-FFFF-FFFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{FFFF00FF-FFFF-FFFF-FFFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{FF00FFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{00FFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FF00-FFFF-FFFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-00FF-FFFF-FFFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FFFF-FF00-FFFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FFFF-00FF-FFFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FFFF-FFFF-00FF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FFFF-FFFF-FF00-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FFFF-FFFF-FFFF-00FFFFFFFFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FFFF-FFFF-FFFF-FF00FFFFFFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FFFF-FFFF-FFFF-FFFF00FFFFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FFFF-FFFF-FFFF-FFFFFF00FFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFF00FF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFF00}"),
    ]
    sorted_bytes.combination(2).each { |(lower, higher)| assert_operator(lower, :<, higher) }
    sorted_uuid_strings.combination(2).each { |(lower, higher)| assert_operator(lower, :<, higher) }
    sorted_guid_strings.combination(2).each { |(lower, higher)| assert_operator(lower, :<, higher) }
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
