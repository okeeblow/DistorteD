require('bundler/setup')
require('test/unit') unless defined?(::Test::Unit)
require_relative('../lib/checking-you-out') unless defined?(::CHECKING::YOU::OUT)

require_relative('only_one_package') unless defined?(::CHECKING::YOU::OUT::OnlyOnePackage)
#using(::CHECKING::YOU::OUT::OnlyOnePackage)

artifact_root = ::CHECKING::YOU::OUT::GEM_ROOT.call.join("TEST MY BEST", "Try 2 Luv. U")
extant_types = ARGV[0].nil? ? ::Dir.glob(
  ::File.join("*", "*"),
  base: artifact_root
) : ::Array[ARGV[0]]

# Separate this test from the normal CYO area to ensure data quality
# with the single-MIME-package refinement.
area_code = :TMB

# Pre-load all available types
::CHECKING::YOU::OUT.set_type_cache_size(::Float::INFINITY, area_code:)
::CHECKING::YOU::OUT[/.*/, area_code:]

# Define a test for every type we have a test file for.
TestTry2LuvU = extant_types.each_with_object(::Class.new(::Test::Unit::TestCase)) { |type, classkey_csupó|
  classkey_csupó.define_method("test_#{type.downcase.gsub(/[\/\-_+\.=;]/, ?_)}_extant_file") {
    cyo = ::CHECKING::YOU::OUT::from_ietf_media_type(type, area_code:)
    # We don't need to `::String#split` on systems where `/` is `::File::SEPARATOR`,
    # but do it anyway for consistency with systems where `::File::ALT_SEPARATOR` is defined.
    artifact_root.join(*type.split(-?/, 2)).glob("**").map(&:realpath).each { |artifact|
      # Double-check that we're working with an extant file even though we just `#glob`ed it.
      assert_path_exist(artifact)

      # We should match at least one Postfix filename-fragment.
      # Skip this comparison if the test fixture has no extname, has a numeric extname,
      # or has an extname containing a space, since those are indicative of filenames
      # without extensions but containing a period in some other context, e.g.:
      #   `irb> ::Pathname::new('CYO MacWrite Pro 1.5 RTF').extname => ".5 RTF"`
      assert_true(
        ::Set[*cyo.sinistar].delete_if(
          &::NilClass::method(:===)
        ).yield_self { |fragments|
          fragments.empty? ? true : fragments.map { |stick_around| stick_around == artifact.to_s }.any?
        }
      ) unless artifact.extname.empty? or artifact.extname.include?(-' ') or (artifact.extname.to_i.to_s == artifact.extname)

      # We should match at least one Glob filename-fragment if the Type defines any
      # and if there is any overlap between the filename and the Glob pattern.
      # The second condition is a workaround for types which define globs for corner-cases
      # instead of as a primary match, e.g. `text/plain`'s `<glob pattern="*,v"/>`.
      assert_true(
        ::Set[*cyo.astraia].delete_if(
          &::NilClass::method(:===)
        ).yield_self { |fragments|
          fragments.empty? ? true : fragments.map { |stick_around| stick_around == artifact.to_s }.any?
        }
      ) unless cyo.astraia.nil? or (
        artifact.basename.to_s.chars.to_set.&(::Set[*cyo.astraia].map!(&:to_s).flat_map(&:chars)).empty?
      )

      # This type or one of its parent types should have at least one content match.
      artifact.open do |stream|
        cyo.adults_table&.map(&:out)&.map(&:cat_sequence)&.delete_if(
          &::NilClass::method(:===)
        )&.map { |cat_sequence|
          cyo.cat_sequence =~ stream
        }
      end

      # The generic CYO interface should return the same result.
      assert_equal(type, ::CHECKING::YOU::OUT(artifact, area_code:).to_s)
    }
  }
}
