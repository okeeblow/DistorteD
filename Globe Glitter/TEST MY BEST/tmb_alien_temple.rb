require('bundler/setup')
require('test/unit') unless defined?(::Test::Unit)
require_relative('../lib/globeglitter') unless defined?(::GlobeGlitter)

class TestGlobeGlitterAlienTemple < Test::Unit::TestCase

  def test_marching_guid_chunks
    ::GlobeGlitter::new(0, layout: ::GlobeGlitter::LAYOUT_MICROSOFT).tap { |gg|

      assert_equal(0, gg.bits127–96)
      gg = gg.with_data1(0xFF00FF00)
      assert_equal(0x00FF00FF, gg.bits127–96)
      assert_equal(0, gg.bits95–80)
      assert_equal(0, gg.bits79–64)
      assert_equal(0, gg.bits63–56)
      assert_equal(0, gg.bits55–48)
      assert_equal(0, gg.bits47–0)
      assert_equal(0, gg.bits63–0)
      gg = gg.with_data1(0)
      assert_equal(0, gg.bits127–96)

      assert_equal(0, gg.bits95–80)
      gg = gg.with_data2(0xFFFF)
      assert_equal(0, gg.bits127–96)
      assert_equal(0xFFFF, gg.bits95–80)
      assert_equal(0, gg.bits79–64)
      assert_equal(0, gg.bits63–56)
      assert_equal(0, gg.bits55–48)
      assert_equal(0, gg.bits47–0)
      assert_equal(0, gg.bits63–0)
      gg = gg.with_data2(0)
      assert_equal(0, gg.bits95–80)

      assert_equal(0, gg.bits79–64)
      gg = gg.with_data3(0xFFFF)
      assert_equal(0, gg.bits127–96)
      assert_equal(0, gg.bits95–80)
      assert_equal(0xFFFF, gg.bits79–64)
      assert_equal(0, gg.bits63–56)
      assert_equal(0, gg.bits55–48)
      assert_equal(0, gg.bits47–0)
      assert_equal(0, gg.bits63–0)
      gg = gg.with_data3(0)
      assert_equal(0, gg.bits79–64)

      assert_equal(0, gg.bits63–0)
      gg = gg.with_data4(::Array::new(8) { 0xFF })
      assert_equal(0, gg.bits127–96)
      assert_equal(0, gg.bits95–80)
      assert_equal(0, gg.bits79–64)
      assert_equal(0xFF, gg.bits63–56)
      assert_equal(0xFF, gg.bits55–48)
      assert_equal(0xFFFFFFFFFFFF, gg.bits47–0)
      assert_equal(0xFFFFFFFF_FFFFFFFF, gg.bits63–0)
      gg = gg.with_data4(::Array::new(8) { 0 })
      assert_equal(0, gg.bits63–56)
      assert_equal(0, gg.bits55–48)
      assert_equal(0, gg.bits47–0)
      assert_equal(0, gg.bits63–0)
    }
  end

end
