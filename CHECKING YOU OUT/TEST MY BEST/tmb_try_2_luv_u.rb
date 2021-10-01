require('test/unit') unless defined?(::Test::Unit)
require_relative('../lib/checking-you-out') unless defined?(::CHECKING::YOU::OUT)

artifact_root = ::CHECKING::YOU::OUT::GEM_ROOT.call.join("TEST-MY-BEST", "Try 2 Luv. U")
extant_types = ARGV[0].nil? ? ::Dir.glob(
  ::File.join("*", "*"),
  base: artifact_root
) : ::Array[ARGV[0]]

# Separate this test from the normal CYO area to ensure data quality
# with the single-MIME-package refinement.
area_code = 'TEST MY BEST'

# Pre-load all available types
::CHECKING::YOU::OUT.send(0, area_code: area_code)
#::CHECKING::YOU::OUT[/.*/, area_code: area_code]

# Define a test for every type we have a test file for.
TestTry2LuvU = extant_types.each_with_object(::Class.new(::Test::Unit::TestCase)) { |type, classkey_csupó|
  classkey_csupó.define_method("test_#{type.downcase.gsub(/[\/\-_+\.=;]/, ?_)}_extant_file") {
    cyo = ::CHECKING::YOU::OUT::from_ietf_media_type(type, area_code: area_code)
    # We don't need to `::String#split` on systems where `/` is `::File::SEPARATOR`,
    # but do it anyway for consistency with systems where `::File::ALT_SEPARATOR` is defined.
    artifact_root.join(*type.split(-?/, 2)).glob("**").map(&:realpath).each { |artifact|
      # Double-check that we're working with an extant file even though we just `#glob`ed it.
      assert_path_exist(artifact)

      # We should match at least one Postfix or Complex filename-fragment.
      assert_true(
        ::Set[*cyo.postfixes, *cyo.complexes].delete_if(
          &::NilClass::method(:===)
        ).map { |stick_around|
          stick_around == artifact.to_s
        }.any?
      )

      # This type or one of its parent types should have at least one content match.
      artifact.open do |stream|
        cyo.adults_table.map(&:out).map(&:cat_sequence).delete_if(
          &::NilClass::method(:===)
        ).map { |cat_sequence|
          cyo.cat_sequence =~ stream
        }
      end

      # The generic CYO interface should return the same result.
      assert_equal(type, ::CHECKING::YOU::OUT(artifact, area_code: area_code).to_s)
    }
  }
}
