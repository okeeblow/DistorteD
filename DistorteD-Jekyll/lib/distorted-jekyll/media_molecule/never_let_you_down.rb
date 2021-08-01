require 'set'

require 'distorted/checking_you_out'
using ::DistorteD::CHECKING::YOU::OUT
require 'distorted-jekyll/liquid_liquid'

module Jekyll; end
module Jekyll::DistorteD; end
module Jekyll::DistorteD::Molecule; end
module Jekyll::DistorteD::Molecule::NeverLetYouDown

  FALLBACK_TYPE = ::CHECKING::YOU::OUT::from_ietf_media_type('application/x.distorted.never-let-you-down')
  LOWER_WORLD = Hash[
    FALLBACK_TYPE => Hash[
      :alt => Cooltrainer::Compound.new(:alt, blurb: 'Alternate text to display when this element cannot be rendered.'),
      :title => Cooltrainer::Compound.new(:title, blurb: 'Extra information about this element — usually displayed as tooltip text.'),
      :href => Cooltrainer::Compound.new(:href, blurb: 'Hyperlink reference for this element.')
    ]
  ]
  OUTER_LIMITS = Hash[FALLBACK_TYPE => nil]

  define_method(FALLBACK_TYPE.distorted_file_method) { |dest_root, change|
    copy_file(change.path(dest_root))
  }
  define_method(FALLBACK_TYPE.distorted_template_method) { |change|
    Cooltrainer::ElementalCreation.new(:anchor_inline, change, **{})
  }

end
