require('test/unit') unless defined?(::Test::Unit)
require('pathname') unless defined?(::Pathname)
require('set') unless defined?(::Set)
require_relative('../lib/checking-you-out') unless defined?(::CHECKING::YOU::OUT)

class TestInnerSpirit < Test::Unit::TestCase

  def test_metadata_generators
    assert_kind_of(::Proc, ::CHECKING::YOU::OUT::GEM_ROOT)
    assert_kind_of(::Pathname, ::CHECKING::YOU::OUT::GEM_ROOT.call)
    assert_kind_of(::Integer, ::CHECKING::YOU::OUT::GEM_PACKAGE_TIME)
  end

  def test_cyi_cyo_relationships
    jpeg_in = ::CHECKING::YOU::IN.new(:possum, :image, :jpeg)
    jpeg_out = ::CHECKING::YOU::OUT.new(:possum, :image, :jpeg)
    png_out = ::CHECKING::YOU::OUT.new(:possum, :image, :png)

    # `CYI#eql?` matches any CYI/CYO with the same `#values`.
    assert_equal(jpeg_in, jpeg_out)
    assert_not_equal(jpeg_in, png_out)

    # A `CYO` can generate a new `CYI` from itself with `#in`.
    assert_equal(jpeg_in, jpeg_out.in)
    assert_equal(jpeg_out.in, jpeg_out.in)

    # A `CYO` is a kind of `CYI` but not an instance of.
    assert_kind_of(jpeg_in.class, jpeg_out)
    assert_instance_of(jpeg_in.class, jpeg_out.in)
    assert_not_instance_of(jpeg_in.class, jpeg_out)
    assert_kind_of(jpeg_in.class, png_out)
    assert_instance_of(jpeg_out.class, png_out)
    assert_instance_of(jpeg_in.class, png_out.in)
    assert_not_instance_of(jpeg_in.class, png_out)

    # Make sure there's equality between `::String`- and `::Symbol`-defined CYIs.
    assert_equal(jpeg_in, ::CHECKING::YOU::IN.new('possum', 'image', 'jpeg'))
    assert_not_equal(jpeg_in, ::CHECKING::YOU::IN.new('possum', 'image', 'png'))

    # `CYI#eql?` should also match `::String`s against the output of `CYI#to_s`.
    # More comprehensive tests for the IETF Media-Type parser and `CYI#to_s`
    # can be found in `tmb_auslandsgesprach.rb`.
    assert_equal(jpeg_in, 'image/jpeg')
    assert_not_equal(jpeg_in, 'image/png')
  end

  def test_add_remove_filename_fragments
    # A CYO can take filename-match fragments which are treated slightly differently
    # depending on whether they represent an extname-only "Postfix" or a more "Complex" match.
    cyo = ::CHECKING::YOU::OUT.new(:cooltrainer, :example, :type)
    postfix1 = ::CHECKING::YOU::OUT::StickAround.new('*.fart')
    postfix2 = ::CHECKING::YOU::OUT::StickAround.new('*.smella')
    complex1 = ::CHECKING::YOU::OUT::StickAround.new('More*[Cc]omplex')

    # All filename-matching containers should be not just empty but `nil`
    # since they avoid allocating spurious `::Enumerable`s.
    #
    # `CYO#extname` is a not a container but a method which will return a `::String` object
    # representing the primary extname for that type, formatted identically to `File::extname`'s output.
    assert_nil(cyo.postfixes)
    assert_nil(cyo.complexes)
    assert_nil(cyo.extname)

    # When we add the first Postfix fragment we will gain an `#extname` too.
    cyo.add_pathname_fragment(postfix1)
    assert_instance_of(postfix1.class, cyo.postfixes)
    assert_equal(postfix1, cyo.postfixes)
    assert_nil(cyo.complexes)
    assert_equal(postfix1[1..], cyo.extname)

    # When we add a second Postfix the `#extname` will not change but the `:@postfixes` IVar
    # will be UpgrayeDD to a `::Set` holding both given Poxtfixes.
    cyo.add_pathname_fragment(postfix2)
    assert_equal(cyo.postfixes.size, 2)
    assert_not_equal(cyo.postfixes, postfix1)
    assert_instance_of(::Set, cyo.postfixes)
    assert_include(cyo.postfixes, postfix1)
    assert_include(cyo.postfixes, postfix2)
    assert_equal(postfix1[1..], cyo.extname)

    # When we add a Complex fragment it will not affect the `#extname` or `:@postfixes` at all.
    cyo.add_pathname_fragment(complex1)
    assert_equal(cyo.postfixes.size, 2)
    assert_instance_of(complex1.class, cyo.complexes)
    assert_equal(complex1, cyo.complexes)

    # When we clear our CYO's known fragments it should be in an identical state as when we started.
    cyo.clear_pathname_fragments
    assert_nil(cyo.postfixes)
    assert_nil(cyo.complexes)
    assert_nil(cyo.extname)
  end

end
