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

  def test_dotnet_system_guid_compareto_comparator
    # Example values from https://learn.microsoft.com/en-us/dotnet/api/system.guid.compareto
    main_guid = ::GlobeGlitter::new("01e75c83-c6f5-4192-b57e-7427cec5560d", layout: ::GlobeGlitter::LAYOUT_MICROSOFT)
    guid2 = ::GlobeGlitter::new(0x01e75c83, 0xc6f5, 0x4192, [0xb5, 0x7e, 0x74, 0x27, 0xce, 0xc5, 0x56, 0x0c], layout: ::GlobeGlitter::LAYOUT_MICROSOFT)
    guid3 = ::GlobeGlitter::new("01e75c84-c6f5-4192-b57e-7427cec5560d", layout: ::GlobeGlitter::LAYOUT_MICROSOFT)
    assert_operator(main_guid, :>, guid2)
    assert_operator(main_guid, :<, guid3)

    # Adapted from the second of four examples in Raymond Chen's
    # “How many ways are there to sort GUIDs? How much time do you have?”
    # https://devblogs.microsoft.com/oldnewthing/20190426-00/?p=102450
    sorted_bytes = [
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
    ]
    sorted_guid_strings = [
      ::GlobeGlitter::new("{00FFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{FF00FFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{FFFF00FF-FFFF-FFFF-FFFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{FFFFFF00-FFFF-FFFF-FFFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-00FF-FFFF-FFFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FF00-FFFF-FFFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FFFF-00FF-FFFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FFFF-FF00-FFFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FFFF-FFFF-00FF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FFFF-FFFF-FF00-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FFFF-FFFF-FFFF-00FFFFFFFFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FFFF-FFFF-FFFF-FF00FFFFFFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FFFF-FFFF-FFFF-FFFF00FFFFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FFFF-FFFF-FFFF-FFFFFF00FFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFF00FF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFF00}"),
    ]
    sorted_bytes.combination(2).each { |(lower, higher)| assert_equal(-1, lower.<=>(higher, comparator: 2)) }
    sorted_guid_strings.combination(2).each { |(lower, higher)| assert_equal(-1, lower.<=>(higher, comparator: 2)) }
  end

  # Example SQL Server sort from https://bornsql.ca/blog/how-sql-server-stores-data-types-guid/
  def test_microsoft_sql_server_uniqueidentifier_comparator
    # Example values from SQL Server 2005 docs:
    # `https://web.archive.org/web/20190122185434/https://blogs.msdn.microsoft.com/
    #  sqlprogrammability/2006/11/06/how-are-guids-compared-in-sql-server-2005/`
    g1 = ::GlobeGlitter::new("{55666BEE-B3A0-4BF5-81A7-86FF976E763F}")
    g2 = ::GlobeGlitter::new("{8DD5BCA5-6ABE-4F73-B4B7-393AE6BBB849}")
    assert_equal(1, g1.<=>(g2, comparator: 3))
    # Adapted from the third of four examples in Raymond Chen's
    # “How many ways are there to sort GUIDs? How much time do you have?”
    # https://devblogs.microsoft.com/oldnewthing/20190426-00/?p=102450
    sorted_bytes = [
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
    ]
    sorted_guid_strings = [
      ::GlobeGlitter::new("{FFFFFFFF-FFFF-FFFF-FFFF-00FFFFFFFFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FFFF-FFFF-FFFF-FF00FFFFFFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FFFF-FFFF-FFFF-FFFF00FFFFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FFFF-FFFF-FFFF-FFFFFF00FFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFF00FF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFF00}"),
      ::GlobeGlitter::new("{FFFFFFFF-FFFF-FFFF-00FF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FFFF-FFFF-FF00-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FFFF-FF00-FFFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FFFF-00FF-FFFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FF00-FFFF-FFFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-00FF-FFFF-FFFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{FFFFFF00-FFFF-FFFF-FFFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{FFFF00FF-FFFF-FFFF-FFFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{FF00FFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{00FFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF}"),
    ]
    sorted_bytes.combination(2).each { |(lower, higher)| assert_equal(-1, lower.<=>(higher, comparator: 3)) }
    sorted_guid_strings.combination(2).each { |(lower, higher)| assert_equal(-1, lower.<=>(higher, comparator: 3)) }

    # Adapted from https://bornsql.ca/blog/how-sql-server-stores-data-types-guid/
    more_sorted_guid_strings = [
      ::GlobeGlitter::new("{3433DC04-153E-4991-B7FF-056F4A8D9D6F}"),
      ::GlobeGlitter::new("{5BEF8652-E7CC-43A4-962F-0A62F1CB830A}"),
      ::GlobeGlitter::new("{B6963B80-3276-4132-9369-56A0BC9A60E7}"),
      ::GlobeGlitter::new("{E31B3B98-FC94-4D01-B013-6C36E79B38EB}"),
      ::GlobeGlitter::new("{CC05E271-BACF-4472-901C-957568484405}"),
      ::GlobeGlitter::new("{3907FE5F-F618-4C04-A66C-9FCFAA487921}"),
      ::GlobeGlitter::new("{7D99F0DC-19EE-4A6B-A085-B4756A6CB816}"),
      ::GlobeGlitter::new("{A756B8AB-1EA8-4215-B165-BAAFE99020D2}"),
      ::GlobeGlitter::new("{ADA0C238-5877-4296-880E-BED7B1F602DF}"),
      ::GlobeGlitter::new("{27CC7C7B-BE46-486F-B7AF-EAB69C5E6630}"),
    ]
    more_sorted_guid_strings.combination(2).each { |(lower, higher)| assert_equal(-1, lower.<=>(higher, comparator: 3)) }
  end

  def test_platform_guid_comparator
    # Adapted from the fourth of four examples in Raymond Chen's
    # “How many ways are there to sort GUIDs? How much time do you have?”
    # https://devblogs.microsoft.com/oldnewthing/20190426-00/?p=102450
    sorted_bytes = [
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
      ::GlobeGlitter::new(
        [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF],
        layout: ::GlobeGlitter::LAYOUT_MICROSOFT,
      ),
    ]
    sorted_guid_strings = [
      ::GlobeGlitter::new("{00FFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{FF00FFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{FFFF00FF-FFFF-FFFF-FFFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{FFFFFF00-FFFF-FFFF-FFFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FFFF-00FF-FFFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FFFF-FF00-FFFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-00FF-FFFF-FFFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FF00-FFFF-FFFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FFFF-FFFF-FFFF-FF00FFFFFFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FFFF-FFFF-FFFF-00FFFFFFFFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FFFF-FFFF-FF00-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FFFF-FFFF-00FF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFF00}"),
      ::GlobeGlitter::new("{FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFF00FF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FFFF-FFFF-FFFF-FFFFFF00FFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FFFF-FFFF-FFFF-FFFF00FFFFFF}"),
    ]
    sorted_bytes.combination(2).each { |(lower, higher)| assert_equal(-1, lower.<=>(higher, comparator: 4)) }
    sorted_guid_strings.combination(2).each { |(lower, higher)| assert_equal(-1, lower.<=>(higher, comparator: 4)) }
  end

  def test_java_util_uuid_comparator
    # Adapted from Raymond Chen's “Another way to sort GUIDs: Java”
    # https://devblogs.microsoft.com/oldnewthing/20190913-00/?p=102859
    sorted_uuid_strings = [
      ::GlobeGlitter::new("{80000000-0000-0000-8000-000000000000}"),
      ::GlobeGlitter::new("{80FFFFFF-FFFF-FFFF-7FFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{FFFFFFFF-FFFF-FFFF-7FFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{00FFFFFF-FFFF-FFFF-7FFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{7F00FFFF-FFFF-FFFF-7FFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{7FFF00FF-FFFF-FFFF-7FFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{7FFFFF00-FFFF-FFFF-7FFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{7FFFFFFF-00FF-FFFF-7FFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{7FFFFFFF-FF00-FFFF-7FFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{7FFFFFFF-FFFF-00FF-7FFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{7FFFFFFF-FFFF-FF00-7FFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{7FFFFFFF-FFFF-FFFF-80FF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{7FFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{7FFFFFFF-FFFF-FFFF-00FF-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{7FFFFFFF-FFFF-FFFF-7F00-FFFFFFFFFFFF}"),
      ::GlobeGlitter::new("{7FFFFFFF-FFFF-FFFF-7FFF-00FFFFFFFFFF}"),
      ::GlobeGlitter::new("{7FFFFFFF-FFFF-FFFF-7FFF-FF00FFFFFFFF}"),
      ::GlobeGlitter::new("{7FFFFFFF-FFFF-FFFF-7FFF-FFFF00FFFFFF}"),
      ::GlobeGlitter::new("{7FFFFFFF-FFFF-FFFF-7FFF-FFFFFF00FFFF}"),
      ::GlobeGlitter::new("{7FFFFFFF-FFFF-FFFF-7FFF-FFFFFFFF00FF}"),
      ::GlobeGlitter::new("{7FFFFFFF-FFFF-FFFF-7FFF-FFFFFFFFFF00}"),
      ::GlobeGlitter::new("{7FFFFFFF-FFFF-FFFF-7FFF-FFFFFFFFFFFF}"),
    ]
    sorted_uuid_strings.combination(2).each { |(lower, higher)| assert_equal(-1, lower.<=>(higher, comparator: 5)) }
  end

  def test_time_uuid
    333.times {
      t1 = ::GlobeGlitter::from_time
      t2 = ::GlobeGlitter::from_time
      assert_operator(t1, :<, t2)
    }
  end
end
