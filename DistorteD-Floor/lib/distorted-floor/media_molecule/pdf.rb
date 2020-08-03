require 'set'

require 'hexapdf'

require 'distorted/checking_you_out'


module Cooltrainer
  module DistorteD
    class PDF

      MEDIA_TYPE = 'application'.freeze
      SUB_TYPE = 'pdf'.freeze

      MIME_TYPES = CHECKING::YOU::IN("#{MEDIA_TYPE}/#{SUB_TYPE}")

      # https://developer.mozilla.org/en-US/docs/Web/HTML/Element/object#Attributes
      # https://www.adobe.com/content/dam/acom/en/devnet/acrobat/pdfs/pdf_open_parameters.pdf
      PDF_OPEN_PARAMS = Array[
        # Keep the PDF Open Params in the order they are defined
        # in the Adobe documentation, since it says they should
        # be specified in the URL in that same order.
        # Ruby's Set doesn't guarantee order, so use a plain Array here.
        :nameddest,
        :page,
        :comment,
        :collab,
        :zoom,
        :view,
        :viewrect,
        :pagemode,
        :scrollbar,
        :search,
        :toolbar,
        :statusbar,
        :messages,
        :navpanes,
        :highlight,
        :fdf,
      ]
      ATTRS = Set[
        :alt,
        :caption,
        :height,  #<object> viewer container height.
        :width,  # <object> viewer container width.
      ].merge(PDF_OPEN_PARAMS)

      # "You cannot use the reserved characters =, #, and &.
      # There is no way to escape these special characters."
      RESERVED_CHARACTERS_FRAGMENT = '[^=#&]+'.freeze

      FLOAT_INT_FRAGMENT = '[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)'.freeze
      ZERO_TO_ONE_HUNDRED = /^(([1-9]\d?|1\d{1})([.,]\d{0,1})?|100([.,]0{1})?)$/
      BOOLEAN_SET = Set[0, 1, false, true, '0'.freeze, '1'.freeze, 'false'.freeze, 'true'.freeze]

      ATTRS_DEFAULT = {
        :height => '100%'.freeze,
        :width => '100%'.freeze,
        # BEGIN PDF Open Parameters
        :page => 1,
        :view => :Fit,
        :pagemode => :none,
        :scrollbar => 1,
        :toolbar => 1,
        :statusbar => 1,
        :messages => 0,
        :navpanes => 1,
        # END PDF Open Parameters
      }

      # Adobe's PDF Open Parameters documentation sez:
      # "Individual parameters, together with their values (separated by & or #),
      # can be no greater then 32 characters in length."
      # …but then goes on to show some examples (like `comment`)
      # that are clearly longer than 32 characters.
      # Dunno. I'll err on the side of giving you a footgun.
      ATTRS_VALUES = {
        :nameddest => /^#{RESERVED_CHARACTERS_FRAGMENT}$/,
        :page => /\d/,
        :comment => /^#{RESERVED_CHARACTERS_FRAGMENT}$/,
        :collab => /^(DAVFDF|FSFDF|DB)@#{RESERVED_CHARACTERS_FRAGMENT}$/,
        :zoom => /^#{FLOAT_INT_FRAGMENT}(,#{FLOAT_INT_FRAGMENT},#{FLOAT_INT_FRAGMENT})?$/,
        :view => /^Fit(H|V|B|BH|BV(,#{FLOAT_INT_FRAGMENT})?)?$/,
        :viewrect => /^#{FLOAT_INT_FRAGMENT},#{FLOAT_INT_FRAGMENT},#{FLOAT_INT_FRAGMENT},#{FLOAT_INT_FRAGMENT}$/,
        :pagemode => Set[:none, :thumbs, :bookmarks],
        :scrollbar => BOOLEAN_SET,
        :search => /^#{RESERVED_CHARACTERS_FRAGMENT}(,\s#{RESERVED_CHARACTERS_FRAGMENT})*$/,
        :toolbar => BOOLEAN_SET,
        :statusbar => BOOLEAN_SET,
        :messages => BOOLEAN_SET,
        :navpanes => BOOLEAN_SET,
        :fdf => /^#{RESERVED_CHARACTERS_FRAGMENT}$/,
      }


      def self.optimize(src, dest)
        HexaPDF::Document.open(src) do |doc|
          doc.task(
            :optimize,
            compact: true,
            object_streams: :generate,
            xref_streams: :generate,
            compress_pages: false,
          )
          doc.write(dest)
        end
      end

    end  # PDF
  end  # DistorteD
end  # Cooltrainer
