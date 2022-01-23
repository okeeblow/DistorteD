require('bundler/setup')
require('test/unit') unless defined?(::Test::Unit)
require_relative('../lib/xross-the-xoul/version') unless defined?(::XROSS::THE::Version)

class TestXrossVersion < ::Test::Unit::TestCase

  def test_triple_counter_equal
    assert_equal(
      ::XROSS::THE::Version::TripleCounter::new(1, 3, 5),
      ::XROSS::THE::Version::TripleCounter::new(1, 3, 5),
    )
    assert_equal(
      ::XROSS::THE::Version::TripleCounter::new(0, 0, 0),
      ::XROSS::THE::Version::TripleCounter::new(0, 0, 0),
    )
    assert_equal(
      ::XROSS::THE::Version::TripleCounter::new(2),
      ::XROSS::THE::Version::TripleCounter::new(2),
    )
  end

  def test_triple_counter_equal_ish
    assert_match(
      ::XROSS::THE::Version::TripleCounter::new(1, 3, 5),
      ::XROSS::THE::Version::TripleCounter::new(1, 3, 5),
    )
    assert_match(
      ::XROSS::THE::Version::TripleCounter::new(0, 7, 0),
      ::XROSS::THE::Version::TripleCounter::new(0, 7, 7),
    )
    assert_match(
      ::XROSS::THE::Version::TripleCounter::new(2),
      ::XROSS::THE::Version::TripleCounter::new(2),
    )
  end

  def test_triple_counter_greater
    assert_compare(
      ::XROSS::THE::Version::TripleCounter::new(1, 3, 5),
      :>,
      ::XROSS::THE::Version::TripleCounter::new(1, 0, 0),
    )
    assert_compare(
      ::XROSS::THE::Version::TripleCounter::new(1, 0, 0),
      :>,
      ::XROSS::THE::Version::TripleCounter::new(0, 0, 1),
    )
    assert_compare(
      ::XROSS::THE::Version::TripleCounter::new(2),
      :>,
      ::XROSS::THE::Version::TripleCounter::new(1),
    )
  end

  def test_triple_counter_lesser
    assert_compare(
      ::XROSS::THE::Version::TripleCounter::new(1, 0, 0),
      :<,
      ::XROSS::THE::Version::TripleCounter::new(1, 0, 1),
    )
    assert_compare(
      ::XROSS::THE::Version::TripleCounter::new(0, 0, 1),
      :<,
      ::XROSS::THE::Version::TripleCounter::new(1, 0, 1),
    )
    assert_compare(
      ::XROSS::THE::Version::TripleCounter::new(1),
      :<,
      ::XROSS::THE::Version::TripleCounter::new(2),
    )
  end

  def test_triple_counter_greater_equal
    assert_compare(
      ::XROSS::THE::Version::TripleCounter::new(1, 3, 5),
      :>=,
      ::XROSS::THE::Version::TripleCounter::new(1, 0, 0),
    )
    assert_compare(
      ::XROSS::THE::Version::TripleCounter::new(1, 0, 0),
      :>=,
      ::XROSS::THE::Version::TripleCounter::new(1, 0, 0),
    )
    assert_compare(
      ::XROSS::THE::Version::TripleCounter::new(2),
      :>=,
      ::XROSS::THE::Version::TripleCounter::new(1),
    )
    assert_compare(
      ::XROSS::THE::Version::TripleCounter::new(2),
      :>=,
      ::XROSS::THE::Version::TripleCounter::new(2),
    )
  end

  def test_triple_counter_lesser_equal
    assert_compare(
      ::XROSS::THE::Version::TripleCounter::new(1, 0, 0),
      :<=,
      ::XROSS::THE::Version::TripleCounter::new(1, 0, 1),
    )
    assert_compare(
      ::XROSS::THE::Version::TripleCounter::new(0, 0, 1),
      :<=,
      ::XROSS::THE::Version::TripleCounter::new(1, 0, 1),
    )
    assert_compare(
      ::XROSS::THE::Version::TripleCounter::new(1),
      :<=,
      ::XROSS::THE::Version::TripleCounter::new(2),
    )
    assert_compare(
      ::XROSS::THE::Version::TripleCounter::new(2),
      :<=,
      ::XROSS::THE::Version::TripleCounter::new(2),
    )
  end

end
