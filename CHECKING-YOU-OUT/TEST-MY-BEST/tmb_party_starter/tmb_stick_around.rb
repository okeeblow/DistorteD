class TestStickAround < Test::Unit::TestCase
  def setup
    @stick_around_insensitive_down = ::CHECKING::YOU::StickAround.new('doc')
    @stick_around_insensitive_up = ::CHECKING::YOU::StickAround.new('DOC')
    @stick_around_sensitive_down = ::CHECKING::YOU::StickAround.new('doc', case_sensitive: true)
    @stick_around_sensitive_up = ::CHECKING::YOU::StickAround.new('DOC', case_sensitive: true)
    @hash = Hash.new
  end

  def test_stick_around_case_insensitive_sensitive_equal
    assert_equal(@stick_around_insensitive_down, @stick_around_insensitive_up)
    assert_equal(@stick_around_insensitive_down, @stick_around_sensitive_down)
    assert_not_equal(@stick_around_sensitive_down, @stick_around_sensitive_up)
    assert_not_equal(@stick_around_insensitive_down, @stick_around_sensitive_up)
  end

  def test_stick_around_string_equal
    assert_equal(@stick_around_insensitive_down, 'doc')
    assert_equal(@stick_around_insensitive_down, 'DOC')
    assert_equal(@stick_around_sensitive_down, 'doc')
    assert_not_equal(@stick_around_sensitive_down, 'DOC')
  end
end
