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

  # Confession: I am not and have never been a “““Windows programmer”””,
  # so I think it's a good idea to test any random example GUIDs I come across
  # and ensure my software correctly interprets them as Windows-land GUIDs.
  def test_deep_dive_example_guids

    # https://web.archive.org/web/20021122102843/http://genghis.winamp.com/~brennan/wa3/faq.html
    # This is the best possible scenario for GUID examples because it gives us
    # the decomposed forms as well as the hex string.
    #
    # options_guid
    # [0x280876cf, 0x48c0, 0x40bc, [ 0x8e, 0x86, 0x73, 0xce, 0x6b, 0xb4, 0x62, 0xe5 ]]
    assert_equal(
      ::GlobeGlitter::new("{280876CF-48C0-40BC-8E86-73CE6BB462E5}"),
      ::GlobeGlitter::new(0x280876cf, 0x48c0, 0x40bc, [0x8e, 0x86, 0x73, 0xce, 0x6b, 0xb4, 0x62, 0xe5])
    )
    #
    # UI Options GUID
    # {9149C445-3C30-4e04-8433-5A518ED0FDDE}
    # { 0x9149c445, 0x3c30, 0x4e04, { 0x84, 0x33, 0x5a, 0x51, 0x8e, 0xd0, 0xfd, 0xde } };
    assert_equal(
      ::GlobeGlitter::new("{9149C445-3C30-4E04-8433-5A518ED0FDDE}"),
      ::GlobeGlitter::new(0x9149c445, 0x3c30, 0x4e04, [0x84, 0x33, 0x5a, 0x51, 0x8e, 0xd0, 0xfd, 0xde])
    )
    #
    # Playlist Editor GUID
    # {45F3F7C1-A6F3-4ee6-A15E-125E92FC3F8D}
    # { 0x45f3f7c1, 0xa6f3, 0x4ee6, { 0xa1, 0x5e, 0x12, 0x5e, 0x92, 0xfc, 0x3f, 0x8d } };
    assert_equal(
      ::GlobeGlitter::new("{45F3F7C1-A6F3-4EE6-A15E-125E92FC3F8D}"),
      ::GlobeGlitter::new(0x45f3f7c1, 0xa6f3, 0x4ee6, [0xa1, 0x5e, 0x12, 0x5e, 0x92, 0xfc, 0x3f, 0x8d])
    )
  end

end
