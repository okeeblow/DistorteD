require('test/unit') unless defined?(::Test::Unit)
require_relative('../lib/checking-you-out') unless defined?(::CHECKING::YOU::OUT)

extant_types = ::Dir.glob(
  ::File.join("*", "*"),
  base: ::CHECKING::YOU::OUT::GEM_ROOT.call.join("TEST-MY-BEST", "Try 2 Luv. U")
)
artifact_root = ::Pathname::new(__dir__).join("Try 2 Luv. U")

# Separate this test from the normal CYO area to ensure data quality
# with the single-MIME-package refinement.
area_code = 'TEST MY BEST'

# Pre-load all available types
::CHECKING::YOU::OUT.send(0, area_code: area_code)
::CHECKING::YOU::OUT[/.*/, area_code: area_code]

# Define a test for every type we have a test file for.
TestTry2LuvU = extant_types.each_with_object(::Class.new(::Test::Unit::TestCase)) { |type, classkey_csupó|
  classkey_csupó.define_method("test_#{type.downcase.gsub(/[\/\-_+\.=;]/, ?_)}_extant_file") {
    cyo = ::CHECKING::YOU::OUT::from_ietf_media_type(type, area_code: area_code)
    # We don't need to `::String#split` on systems where `/` is `::File::SEPARATOR`,
    # but do it anyway for consistency with systems where `::File::ALT_SEPARATOR` is defined.
    artifact_root.join(*type.split(-?/, 2)).glob("**").each { |artifact|
      assert_path_exist(artifact)

      case cyo.postfixes
      when ::Set then
        assert_true(cyo.postfixes.map { |postfix| postfix == artifact.to_s }.any?)
      when ::CHECKING::YOU::OUT::StickAround then
        assert_true(cyo.postfixes == artifact.to_s)
      end

      case cyo.complexes
      when ::Set then
        assert_true(cyo.complexes.map { |postfix| postfix == artifact.to_s }.any?)
      when ::CHECKING::YOU::OUT::StickAround then
        assert_true(cyo.complexes == artifact.to_s)
      end

      artifact.open do |stream|
        case cyo.cat_sequence
        when ::Set then
          assert_true(cyo.cat_sequence.map { |postfix| postfix =~ stream }.any?)
        else
          assert_true(cyo.cat_sequence =~ stream)
        end
      end
    }
  }
}
