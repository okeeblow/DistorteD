require('pathname') unless defined?(::Pathname)
require('set') unless defined?(::Set)
require('test/unit') unless defined?(::Test::Unit)

require_relative('../../lib/checking-you-out') unless defined?(::CHECKING::YOU::OUT::StickAround)


class TestStickAround < Test::Unit::TestCase

  def setup
    @stick_around_insensitive_down = ::CHECKING::YOU::OUT::StickAround.new('doc')
    @stick_around_insensitive_up = ::CHECKING::YOU::OUT::StickAround.new('DOC')
    @stick_around_sensitive_down = ::CHECKING::YOU::OUT::StickAround.new('doc', case_sensitive: true)
    @stick_around_sensitive_up = ::CHECKING::YOU::OUT::StickAround.new('DOC', case_sensitive: true)
  end

  def make_sensitive(otra);   ::CHECKING::YOU::OUT::StickAround.new(otra, case_sensitive: true);  end
  def make_insensitive(otra); ::CHECKING::YOU::OUT::StickAround.new(otra, case_sensitive: false); end


  # `StickAround` always stores a glob-style `::String` (i.e. for `::File::fnmatch?`)
  # but takes several possible types of input via its `#initialize`/`#replace` methods.
  def test_input_handling
    # Plain-extname `::String` input (e.g. just 'jpg', not '.jpg')
    assert_equal("*.jpg", self.make_insensitive('jpg').to_s)
    assert_equal("*.JPG", self.make_sensitive('JPG').to_s)

    # Plain-extname `::Symbol` input.
    assert_equal("*.jpg", self.make_insensitive(:jpg).to_s)
    assert_equal("*.JPG", self.make_sensitive(:JPG).to_s)

    # Basename `::String` input.
    assert_equal("*.jpg", self.make_insensitive('hello.jpg').to_s)
    assert_equal("*.JPG", self.make_sensitive('hello.JPG').to_s)

    # Full-path `::String` input.
    assert_equal("*.jpg", self.make_insensitive('/home/okeeblow/hello.jpg').to_s)
    assert_equal("*.JPG", self.make_sensitive('/home/okeeblow/hello.JPG').to_s)
    assert_equal("*.jpg", self.make_insensitive('C:\Documents and Settings\Mark Ultra\MYDOCU~1\hello.jpg').to_s)

    # Full-`::Pathname` input.
    assert_equal("*.jpg", self.make_insensitive(::Pathname.new('/home/okeeblow/hello.jpg')).to_s)
    assert_equal("*.JPG", self.make_sensitive(::Pathname.new('/home/okeeblow/hello.JPG')).to_s)
    assert_equal("*.jpg", self.make_insensitive(::Pathname.new('C:\Documents and Settings\Mark Ultra\MYDOCU~1\hello.JPG')).to_s)

    # `StickAround` ouroboros.
    assert_equal("*.jpg", self.make_insensitive(self.make_insensitive('hello.jpg')).to_s)
    assert_equal("*.JPG", self.make_sensitive(self.make_sensitive('hello.JPG')).to_s)
  end

  # `StickAround` vs. `StickAround`
  def test_stick_around_case_insensitive_sensitive_equal
    assert_equal(@stick_around_insensitive_down, @stick_around_insensitive_up)
    assert_equal(@stick_around_insensitive_down, @stick_around_sensitive_down)
    assert_not_equal(@stick_around_sensitive_down, @stick_around_sensitive_up)
    assert_not_equal(@stick_around_insensitive_down, @stick_around_sensitive_up)
  end

  # `StickAround` vs. `String`
  def test_stick_around_string_equal
    assert_equal(@stick_around_insensitive_down, '*.doc')
    assert_equal(@stick_around_insensitive_down, '*.DOC')
    assert_equal(@stick_around_sensitive_down, '*.doc')
    assert_not_equal(@stick_around_sensitive_down, '*.DOC')
    assert_not_equal(@stick_around_sensitive_up, '*.doc')
    assert_not_equal(@stick_around_sensitive_down, '*.DoC')
    assert_not_equal(@stick_around_sensitive_up, '*.DoC')
  end

  # `StickAround` is a `String` subclass and so can't escape MRI's C implementation
  # of `String`-as-`Hash`-key comparison code (`rb_str_hash_cmp`).
  def test_rb_str_hash_cmp
    hash = ::Hash.new
    hash[@stick_around_insensitive_down] = :hey
    hash[@stick_around_sensitive_up] = :sup

    # `StickAround` vs `StickAround`
    assert_equal(hash[@stick_around_sensitive_down], :hey)
    assert_equal(hash[@stick_around_insensitive_down], :hey)
    assert_equal(hash[@stick_around_sensitive_up], :sup)
    assert_equal(hash[@stick_around_insensitive_up], :hey)  # Depends on insert order. We inserted insensitive-lower first.
    assert_not_equal(hash[@stick_around_sensitive_down], :sup)
    assert_not_equal(hash[@stick_around_sensitive_up], :hey)

    # `StickAround` vs `String`
    assert_equal(hash['*.doc'], :hey)

    hash.clear

    # This same C method also applies to `Set` and `#uniq`.
    assert_equal(::Set[@stick_around_insensitive_up, @stick_around_insensitive_down].size, 1)
    assert_equal(::Array[@stick_around_insensitive_up, @stick_around_insensitive_down].uniq!.size, 1)
  end

end
