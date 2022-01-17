require('bundler/setup')
require('pathname') unless defined?(::Pathname)
require('set') unless defined?(::Set)
require('test/unit') unless defined?(::Test::Unit)

require_relative('../../lib/checking-you-out') unless defined?(::CHECKING::YOU::OUT::DeusDextera)


class TestDeusDextera < Test::Unit::TestCase

  def setup
    @deus_dextera_insensitive_down = ::CHECKING::YOU::OUT::DeusDextera.new('.doc')
    @deus_dextera_insensitive_up = ::CHECKING::YOU::OUT::DeusDextera.new('.DOC')
    @deus_dextera_sensitive_down = ::CHECKING::YOU::OUT::DeusDextera.new('.doc', case_sensitive: true)
    @deus_dextera_sensitive_up = ::CHECKING::YOU::OUT::DeusDextera.new('.DOC', case_sensitive: true)
  end

  def make_sensitive(otra);   ::CHECKING::YOU::OUT::DeusDextera.new(otra, case_sensitive: true);  end
  def make_insensitive(otra); ::CHECKING::YOU::OUT::DeusDextera.new(otra, case_sensitive: false); end


  # `DeusDextera` always stores a glob-style `::String` (i.e. for `::File::fnmatch?`)
  # but takes several possible types of input via its `#initialize`/`#replace` methods.
  def test_input_handling
    # Plain-extname `::String` input (e.g. just 'jpg', not '.jpg')
    assert_equal("*.jpg", self.make_insensitive('.jpg').to_s)
    assert_equal("*.JPG", self.make_sensitive('.JPG').to_s)

    # Plain-extname `::Symbol` input.
    assert_equal("*.jpg", self.make_insensitive(:jpg).to_s)
    assert_equal("*.JPG", self.make_sensitive(:JPG).to_s)

    # Basename `::String` input.
    assert_equal("*.jpg", self.make_insensitive(::File::extname('hello.jpg')).to_s)
    assert_equal("*.JPG", self.make_sensitive(::File::extname('hello.JPG')).to_s)

    # Full-path `::String` input.
    assert_equal("*.jpg", self.make_insensitive('/home/okeeblow/hello.jpg').to_s)
    assert_equal("*.JPG", self.make_sensitive('/home/okeeblow/hello.JPG').to_s)
    #assert_equal("*.jpg", self.make_insensitive('C:\Documents and Settings\Mark Ultra\MYDOCU~1\hello.jpg').to_s)

    # Full-`::Pathname` input.
    assert_equal("*.jpg", self.make_insensitive(::Pathname.new('/home/okeeblow/hello.jpg')).to_s)
    assert_equal("*.JPG", self.make_sensitive(::Pathname.new('/home/okeeblow/hello.JPG')).to_s)
    assert_equal("*.jpg", self.make_insensitive(::Pathname.new('C:\Documents and Settings\Mark Ultra\MYDOCU~1\hello.JPG')))

    # `DeusDextera` ouroboros.
    assert_equal("*.jpg", self.make_insensitive(self.make_insensitive('hello.jpg')).to_s)
    assert_equal("*.JPG", self.make_sensitive(self.make_sensitive('hello.JPG')).to_s)
  end

  # `DeusDextera` vs. `DeusDextera`
  def test_deus_dextera_case_insensitive_sensitive_equal
    assert_equal(@deus_dextera_insensitive_down, @deus_dextera_insensitive_up)
    assert_equal(@deus_dextera_insensitive_down, @deus_dextera_sensitive_down)
    assert_not_equal(@deus_dextera_sensitive_down, @deus_dextera_sensitive_up)
    assert_not_equal(@deus_dextera_insensitive_down, @deus_dextera_sensitive_up)
  end

  # `DeusDextera` vs. `String`
  def test_deus_dextera_string_equal
    assert_equal(@deus_dextera_insensitive_down, '*.doc')
    assert_equal(@deus_dextera_insensitive_down, '*.DOC')
    assert_equal(@deus_dextera_sensitive_down, '*.doc')
    assert_not_equal(@deus_dextera_sensitive_down, '*.DOC')
    assert_not_equal(@deus_dextera_sensitive_up, '*.doc')
    assert_not_equal(@deus_dextera_sensitive_down, '*.DoC')
    assert_not_equal(@deus_dextera_sensitive_up, '*.DoC')
  end

  # `DeusDextera` is a `String` subclass and so can't escape MRI's C implementation
  # of `String`-as-`Hash`-key comparison code (`rb_str_hash_cmp`).
  def test_rb_str_hash_cmp
    hash = ::Hash.new
    hash[@deus_dextera_insensitive_down] = :hey
    hash[@deus_dextera_sensitive_up] = :sup

    # `DeusDextera` vs `DeusDextera`
    assert_equal(hash[@deus_dextera_sensitive_down], :hey)
    assert_equal(hash[@deus_dextera_insensitive_down], :hey)
    assert_equal(hash[@deus_dextera_sensitive_up], :sup)
    assert_equal(hash[@deus_dextera_insensitive_up], :hey)  # Depends on insert order. We inserted insensitive-lower first.
    assert_not_equal(hash[@deus_dextera_sensitive_down], :sup)
    assert_not_equal(hash[@deus_dextera_sensitive_up], :hey)

    # `DeusDextera` vs `String`
    assert_equal(hash['*.doc'], :hey)

    hash.clear

    # This same C method also applies to `Set` and `#uniq`.
    assert_equal(::Set[@deus_dextera_insensitive_up, @deus_dextera_insensitive_down].size, 1)
    assert_equal(::Array[@deus_dextera_insensitive_up, @deus_dextera_insensitive_down].uniq!.size, 1)
  end

  def test_from_string
    assert_equal("*.zip", ::CHECKING::YOU::OUT::DeusDextera::from_string("*.zip"))
    assert_raise(::ArgumentError) do
      ::CHECKING::YOU::OUT::DeusDextera::from_string("Not a valid glob lmao")
    end
    assert_raise(::ArgumentError) do
      # Single `extname`s only for this class!
      ::CHECKING::YOU::OUT::DeusDextera::from_string("*.7z.001")
    end
  end

end
