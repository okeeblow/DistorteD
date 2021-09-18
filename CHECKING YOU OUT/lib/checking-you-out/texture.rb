
# Components to track static information about a CYO type, e.g.
# - Plain-text description.
# - Acronyms (and their meaning).
# - Recommended icon names.
module ::CHECKING::YOU::OUT::TEXTURE

  # Storage for freeform type descriptions (`<comment>` elements), type acrnyms,
  # suitable iconography, and other boring metadata, e.g.:
  #
  #   <mime-type type="application/vnd.oasis.opendocument.text">
  #     <comment>ODT document</comment>
  #     <acronym>ODT</acronym>
  #     <expanded-acronym>OpenDocument Text</expanded-acronym>
  #     <generic-icon name="x-office-document"/>
  #     […]
  #   </mini-type>

  # For `<comment/>`.
  attr_accessor(:description)

  # Container for short and expanded acronym.
  ACRNYM = ::Struct.new(:acronym, :description) do
    # e.g. `"PDF (Portable Document Format)"`
    def to_s; "#{self[:acronym]} (#{self[:description]})".-@; end
  end

  # For `<acronym/>` and `<expanded-acronym/>`.
  def acronym; @acrnym ||= ACRNYM.new; end
  def acronym=(otra)
    self.acronym.send(otra.include?(-' ') ? :description= : :acronym=, otra)
  end

end
