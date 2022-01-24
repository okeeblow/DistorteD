require 'set'

require 'hexapdf'

require 'distorted-floor/checking_you_out'
using ::DistorteD::CHECKING::YOU::OUT


module Cooltrainer; end
module Cooltrainer::DistorteD; end
module Cooltrainer::DistorteD::Molecule; end
module Cooltrainer::DistorteD::Molecule::PDF


  # https://hexapdf.gettalong.org/documentation/reference/api/HexaPDF/Document/index.html#method-c-new
  # https://hexapdf.gettalong.org/documentation/reference/api/HexaPDF/index.html#DefaultDocumentConfiguration
  # https://hexapdf.gettalong.org/documentation/reference/api/HexaPDF/Task/Optimize.html
  PDF_TYPE = ::CHECKING::YOU::OUT::from_iana_media_type('application/pdf')
  LOWER_WORLD = Hash[
    PDF_TYPE => nil,
  ]
  OUTER_LIMITS = Hash[
    PDF_TYPE => nil,
  ]

  # TODO: Use MuPDF instead of libvips magick-based PDF loader.

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

  define_method(PDF_TYPE.distorted_file_method) { |dest_root, change|
    copy_file(change.paths(dest_root).first)
  }

end  # PDF
