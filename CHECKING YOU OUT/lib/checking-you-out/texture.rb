
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

  # For `<comment/>` — I want to call it 'description' instead of 'comment' because idk
  attr_accessor(:description, :acronym)

  # Container for short and expanded acronym.
  ACRNYM = ::Struct.new(:initialism, :meaning) do
    # e.g. `"PDF (Portable Document Format)"`
    def to_s; "#{self[:initialism]} (#{self[:meaning]})".-@; end
  end

  # For `<acronym/>` and `<expanded-acronym/>`.
  # Both elements' callback will invoke this same setter since:
  # - there can only be one of each per the `shared-mime-info` DTD
  # - they are stored in a single `Struct` together.
  # We decide which `Struct` setter to call based on the presense of a space (' ').
  # TOD0: Change this iff I find a breaking case (an `<expanded-acronym/>` with no space)
  def acronym=(otra)
    (@acronym ||= ACRNYM.new).send(otra.include?(-' ') ? :meaning= : :initialism=, otra)
  end

end
