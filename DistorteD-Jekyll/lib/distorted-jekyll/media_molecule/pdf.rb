require 'set'

require 'distorted-floor/checking_you_out'
using ::DistorteD::CHECKING::YOU::OUT
require 'distorted-floor/media_molecule/pdf'


module Jekyll; end
module Jekyll::DistorteD; end
module Jekyll::DistorteD::Molecule; end
module Jekyll::DistorteD::Molecule::PDF

  include Cooltrainer::DistorteD::Molecule::PDF

  # https://www.adobe.com/content/dam/acom/en/devnet/acrobat/pdfs/pdf_open_parameters.pdf
  #
  # Adobe's PDF Open Parameters documentation sez:
  # "Individual parameters, together with their values (separated by & or #),
  # can be no greater then 32 characters in length."
  # …but then goes on to show some examples (like `comment`)
  # that are clearly longer than 32 characters.
  # Dunno. I'll err on the side of giving you a footgun.
  #
  # Keep the PDF Open Params in the order they are defined
  # in the Adobe documentation, since it says they should
  # be specified in the URL in that same order.
  #
  # "You cannot use the reserved characters =, #, and &.
  # There is no way to escape these special characters."
  RESERVED_CHARACTERS_FRAGMENT = '[^=#&]+'.freeze
  FLOAT_INT_FRAGMENT = '[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)'.freeze
  ZERO_TO_ONE_HUNDRED = /^(([1-9]\d?|1\d{1})([.,]\d{0,1})?|100([.,]0{1})?)$/
  PDF_OPEN_PARAMS = Array[
    Cooltrainer::Compound.new(:nameddest, valid: /^#{RESERVED_CHARACTERS_FRAGMENT}$/, blurb: 'Jump to a named destination in the document.'),
    Cooltrainer::Compound.new(:page, valid: Integer, default: 1, blurb: 'Jump to a numbered page in the document.'),
    Cooltrainer::Compound.new(:comment, valid: /^#{RESERVED_CHARACTERS_FRAGMENT}$/, blurb: 'Jump to a comment on a given page.'),
    Cooltrainer::Compound.new(:collab, valid: /^(DAVFDF|FSFDF|DB)@#{RESERVED_CHARACTERS_FRAGMENT}$/, blurb: 'Sets the comment repository to be used to supply and store comments for the document.'),
    Cooltrainer::Compound.new(:zoom, valid: /^#{FLOAT_INT_FRAGMENT}(,#{FLOAT_INT_FRAGMENT},#{FLOAT_INT_FRAGMENT})?$/, blurb: 'Sets the zoom and scroll factors, using float or integer values.'),
    Cooltrainer::Compound.new(:view, valid: /^Fit(H|V|B|BH|BV(,#{FLOAT_INT_FRAGMENT})?)?$/, default: :Fit, blurb: 'Set the view of the displayed page, using the keyword values defined in the PDF language specification. For more information, see the PDF Reference.'),
    Cooltrainer::Compound.new(:viewrect, valid: /^#{FLOAT_INT_FRAGMENT},#{FLOAT_INT_FRAGMENT},#{FLOAT_INT_FRAGMENT},#{FLOAT_INT_FRAGMENT}$/, blurb: 'Sets the view rectangle using float or integer values in a coordinate system where 0,0 represents the top left corner of the visible page, regardless of document rotation.'),
    Cooltrainer::Compound.new(:pagemode, valid: Set[:none, :thumbs, :bookmarks], default: :none, blurb: 'Displays bookmarks or thumbnails.'),
    Cooltrainer::Compound.new(:scrollbar, valid: Cooltrainer::BOOLEAN_VALUES, default: true, blurb: 'Turns scrollbars on or off.'),
    Cooltrainer::Compound.new(:search, valid: /^#{RESERVED_CHARACTERS_FRAGMENT}(,\s#{RESERVED_CHARACTERS_FRAGMENT})*$/ , blurb: 'Opens the Search panel and performs a search for any of the words in the specified word list. The first matching word is highlighted in the document.'),
    Cooltrainer::Compound.new(:toolbar, valid: Cooltrainer::BOOLEAN_VALUES, default: true, blurb: 'Turns the toolbar on or off.'),
    Cooltrainer::Compound.new(:statusbar, valid: Cooltrainer::BOOLEAN_VALUES, default: true, blurb: 'Turns the status bar on or off.'),
    Cooltrainer::Compound.new(:messages, valid: Cooltrainer::BOOLEAN_VALUES, default: false, blurb: 'Turns the document message bar on or off.'),
    Cooltrainer::Compound.new(:navpanes, valid: Cooltrainer::BOOLEAN_VALUES, default: true, blurb: 'Turns the navigation panes and tabs on or off.'),
    Cooltrainer::Compound.new(:highlight, valid: /^#{FLOAT_INT_FRAGMENT},#{FLOAT_INT_FRAGMENT},#{FLOAT_INT_FRAGMENT},#{FLOAT_INT_FRAGMENT}$/, blurb: 'Highlights a specified rectangle on the displayed page. Use the `page` command before this command.'),
    Cooltrainer::Compound.new(:fdf, valid: /^#{RESERVED_CHARACTERS_FRAGMENT}$/, blurb: 'Specifies an FDF file to populate form fields in the PDF file being
opened.'),
  ]

  # https://developer.mozilla.org/en-US/docs/Web/HTML/Element/object#Attributes
  CONTAINER_ATTRIBUTES = Array[
    Cooltrainer::Compound.new(:alt, valid: String),
    Cooltrainer::Compound.new(:caption, valid: String),
    Cooltrainer::Compound.new(:height,  valid: String, default: '100%'.freeze, blurb: '<object> viewer container height.'),
    Cooltrainer::Compound.new(:width,  valid: String, default: '100%'.freeze, blurb: '<object> viewer container width.'),
  ]

  OUTER_LIMITS = Hash[
    ::CHECKING::YOU::OUT::from_iana_media_type(-'application/pdf') => PDF_OPEN_PARAMS.concat(CONTAINER_ATTRIBUTES).reduce(Hash[]) {|aka, compound|
      aka.tap { |a| a.store(compound.element, compound) }
    }
  ]

  # Generate a Hash of our PDF Open Params based on any given to the Liquid tag
  # and any loaded from the defaults.
  # https://www.adobe.com/content/dam/acom/en/devnet/acrobat/pdfs/pdf_open_parameters.pdf
  def pdf_open_params
    PDF_OPEN_PARAMS.reduce(Hash[]) {|params, compound|
      # Only include those params whose user-given value exists and differs from its default.
      params.tap { |p|
        p.store(compound.element, abstract(compound.element)) unless [
          nil, ''.freeze, compound.default,
        ].include?(abstract(compound.element))
      }
    }
  end

  # Generate the URL fragment version of the PDF Open Params.
  # This would be difficult / impossible to construct within Liquid
  # from the individual variables, so let's just do it out here.
  def pdf_open_params_url
    pdf_open_params.map{ |(k,v)|
      case
      when k == :search
        # The PDF Open Params docs specify `search` should be quoted.
        "#{k}=\"#{v}\""
      when Cooltrainer::BOOLEAN_VALUES.include?(v)
        # Convert booleans to the numeric representation Adobe use here.
        "#{k}=#{v ? 1 : 0}"
      else
        "#{k}=#{v}"
      end
    }.join('&')
  end

  # http://joliclic.free.fr/html/object-tag/en/
  # TODO: iOS treats our <object> like an <img>,
  # showing only the first page with transparency and stretched to the
  # size of the container element.
  # We will need something like PDF.js in an <iframe> to handle this.
  define_method(::CHECKING::YOU::OUT::from_iana_media_type('application/pdf').distorted_template_method) { |change|
    Cooltrainer::ElementalCreation.new(:object, change, children: [:embed, :anchor_inline]).tap { |e|
      e.fragment = pdf_open_params.empty? ? ''.freeze : "##{pdf_open_params_url}"
    }
  }

end  # PDF
