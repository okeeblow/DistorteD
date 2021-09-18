
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
  attr_accessor(:description)

end
