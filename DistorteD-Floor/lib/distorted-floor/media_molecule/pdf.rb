require 'set'

require 'hexapdf'

require 'distorted/checking_you_out'


module Cooltrainer; end
module Cooltrainer::DistorteD; end
module Cooltrainer::DistorteD::Molecule; end
module Cooltrainer::DistorteD::Molecule::PDF


  # https://hexapdf.gettalong.org/documentation/reference/api/HexaPDF/Document/index.html#method-c-new
  # https://hexapdf.gettalong.org/documentation/reference/api/HexaPDF/index.html#DefaultDocumentConfiguration
  # https://hexapdf.gettalong.org/documentation/reference/api/HexaPDF/Task/Optimize.html
  LOWER_WORLD = Hash[
    CHECKING::YOU::OUT['application/pdf'] => nil,
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

  def to_application_pdf_file(*a, **k, &b)
    copy_file(*a, **k, &b)
  end

end  # PDF
