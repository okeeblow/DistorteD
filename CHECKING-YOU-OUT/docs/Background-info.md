
# Background info


## Object ID

 https://en.wikipedia.org/wiki/Object_identifier
 http://www.oid-info.com/
 https://www.alvestrand.no/objectid/
 https://en.wikipedia.org/wiki/Universally_unique_identifier

## PRONOM

 https://www.nationalarchives.gov.uk/PRONOM/Default.aspx
 https://www.nationalarchives.gov.uk/aboutapps/pronom/droid-signature-files.htm
 https://github.com/digital-preservation/droid/blob/master/Signature%20syntax.md
 https://github.com/digital-preservation/droid/tree/master/droid-command-line/src/test/resources/signatures
 https://github.com/digital-preservation/droid/tree/master/droid-results/src/main/resources
 https://github.com/digital-preservation/droid/tree/master/droid-container/src/main/resources

## Macintosh / Amiga / QuickTime / VFW / DirectX typing (FourCC)

 - http://abcavi.kibi.ru/fourcc.php
 - https://wiki.awkwardtv.org/wiki/QT_Codec_Information#Identify_.22ms.22_audio

## IETF types

 - https://www.iana.org/assignments/media-types/media-types.xhtml
 - https://www.iana.org/assignments/media-type-structured-suffix/media-type-structured-suffix.xml
 - https://tools.ietf.org/html/rfc5234
 - https://en.wikipedia.org/wiki/Backus%E2%80%93Naur_form
 - http://xahlee.info/parser/bnf_ebnf_abnf.html
 - http://matt.might.net/articles/grammars-bnf-ebnf/
 - https://github.com/Engelberg/instaparse/blob/master/docs/ABNF.md
 - https://www.garshol.priv.no/download/text/bnf.html


 Based on the ABNF (Adult Baby Normal Form) specifications and textual descriptions excerpted from…

 - RFC 1049 — https://tools.ietf.org/html/rfc1049#section-3

      Content-Type:= type [";" ver-num [";" 1#resource-ref]] [comment]

   Initially, the type parameter would be limited to the following set of values:

      type:= "POSTSCRIPT"/"SCRIBE"/"SGML"/"TEX"/"TROFF"/"DVI"/"X-"atom

   These values are not case sensitive.  POSTSCRIPT, Postscript, and POStscriPT are all equivalent.

      […]
      "X-"atom        Any type value beginning with the characters "X-" is a private value.

   Since standard structuring techniques in fact evolve over time, we leave room for specifying a version number
   for the content type.  Valid values will depend upon the type parameter.

      ver-num:=      local-part
      resource-ref:=  local-part

   The comment field can be any additional comment text the user desires.
   Comments are enclosed in parentheses as specified in [RFC-822].


 - RFC 1590 — https://tools.ietf.org/html/rfc1590

   Send a proposed Media Type (content-type/subtype) to the "ietf-types@cs.utk.edu" mailing list.
   This mailing list has been established for the sole purpose of reviewing proposed Media Types.
   Proposed content-types are not formally registered and must use the "x-" notation for the subtype name.


 - RFC 2045 — https://tools.ietf.org/html/rfc2045#section-5

      content := "Content-Type" ":" type "/" subtype
                 *(";" parameter)
                 ; Matching of media type and subtype
                 ; is ALWAYS case-insensitive.

      type := discrete-type / composite-type

      discrete-type := "text" / "image" / "audio" / "video" /
                       "application" / extension-token

      composite-type := "message" / "multipart" / extension-token

      extension-token := ietf-token / x-token

      ietf-token := <An extension token defined by a
                     standards-track RFC and registered
                     with IANA.>

      x-token := <The two characters "X-" or "x-" followed, with
                  no intervening white space, by any token>

      subtype := extension-token / iana-token

      iana-token := <A publicly-defined extension token. Tokens
                     of this form must be registered with IANA
                     as specified in RFC 2048.>

      […and some more I cut out for space] 

   The type, subtype, and parameter names are not case sensitive.  For example, `TEXT`, `Text`, and `TeXt`
   are all equivalent top-level media types.  Parameter values are normally case sensitive,
   but sometimes are interpreted in a case-insensitive fashion, depending on the intended use. 
   (For example, multipart boundaries are case-sensitive, but the "access-type" parameter
   for message/External-body is not case-sensitive.)

   After the media type and subtype names, the remainder of the header field is simply a set of parameters,
   specified in an attribute=value notation.  The ordering of parameters is not significant.
   
   Note that the value of a quoted string parameter does not include the quotes.
   That is, the quotation marks in a quoted-string are not a part of the value of the parameter,
   but are merely used to delimit that parameter value.

   In addition, comments are allowed in accordance with RFC 822 rules for structured header fields.
   
   Thus the following two forms:
       `Content-type: text/plain; charset=us-ascii (Plain text)`
       `Content-type: text/plain; charset="us-ascii"`
   are completely equivalent.


 - RFC 2048 — https://tools.ietf.org/html/rfc2048#section-2.1

   The IETF tree is intended for types of general interest to the Internet Community. Registration in the IETF tree
   requires approval by the IESG and publication of the media type registration as some form of RFC.
   Media types in the IETF tree are normally denoted by names that are not explicitly faceted,
   i.e., do not contain period (".", full stop) characters.

   The vendor tree is used for media types associated with commercially available products.
   Registrations in the vendor tree will be distinguished by the leading facet "vnd.".  That may be followed,
   at the discretion of the registration, by either a media type name from a well-known producer (e.g., "vnd.mudpie")
   or by an IANA-approved designation of the producer's name which is then followed by a media type
   or product designation (e.g., vnd.bigcompany.funnypictures).

   Registrations for media types created experimentally or as part of products that are not distributed commercially
   may be registered in the personal or vanity tree.  The registrations are distinguished by the leading facet "prs.".

   For convenience and symmetry with this registration scheme, media type names with "x." as the first facet
   may be used for the same purposes for which names starting in "x-" are normally used.
   These types are unregistered, experimental, and should be used only with the active agreement
   of the parties exchanging them.


 - RFC 2077 — https://tools.ietf.org/html/rfc2077

   "The purpose of this memo is to propose an update to [Internet RFC 2045] to include
   a new primary content-type to be known as "model". RFC 2045 describes mechanisms for specifying and describing
   the format of Internet Message Bodies via content-type/subtype pairs. We believe that "model" defines
   a fundamental type of content with unique presentational, hardware, and processing aspects."


 - RFC 2376 — https://tools.ietf.org/html/rfc2376#section-3

   Every XML entity is suitable for use with the application/xml media type without modification.
   But this does not exploit the fact that XML can be treated as plain text in many cases. 
   MIME user agents (and web user agents) that do not have explicit support for `application/xml`
   will treat it as `application/octet-stream`, for example, by offering to save it to a file.
   To indicate that an XML entity should be treated as plain text by default, use the `text/xml` media type.
   This restricts the encoding used in the XML entity to those that are compatible with the requirements
   for text media types as described in [RFC-2045] and [RFC-2046], e.g., UTF-8, but not UTF-16 (except for HTTP).


 - RFC 3023 — https://tools.ietf.org/html/rfc3023#section-7
              https://tools.ietf.org/html/rfc3023#appendix-A

   Although the use of a suffix was not considered as part of the original MIME architecture,
   this choice is considered to provide the most functionality with the least potential
   for interoperability problems or lack of future extensibility. The alternatives to the '+xml' suffix
   and the reason for its selection are described [in RFC 3023 Appendix A].

   The subtree under which a media type is registered — IETF, vendor (*/vnd.*), or personal (*/prs.*);
   see [RFC2048] for details — is completely orthogonal from whether the media type uses XML syntax or not.
   The suffix approach allows XML document types to be identified within any subtree.
   The vendor subtree, for example, is likely to include a large number of XML-based document types.
   By using a suffix, rather than setting up a separate subtree, those types may remain in the same location
   in the tree of MIME types that they would have occupied had they not been based on XML.

   The top-level MIME type (e.g., model/*[RFC2077]) determines what kind of content the type is,
   not what syntax it uses.  For example, agents using image/* to signal acceptance of any image format
   should certainly be given access to media type image/svg+xml, which is in all respects a standard image subtype.
   It just happens to use XML to describe its syntax.  The two aspects of the media type are completely orthogonal.
   XML-based data types will most likely be registered in ALL top-level categories.  Potential, though
   currently unregistered, examples could include `application/mathml+xml`[MathML] and `image/svg+xml`[SVG].

   In the ten years that MIME has existed [written 2001, ed.], XML is the first generic data format that
   has seemed to justify special treatment, so it is hoped that no further suffixes will be necessary.
   However, if some are later defined, and these documents were also XML, they would need to specify that
   the '+xml' suffix is always the outermost suffix (e.g., application/foo+ebml+xml not application/foo+xml+ebml).
   If they were not XML, then they would use a regular suffix (e.g., application/foo+ebml).


 - RFC 4288 — https://tools.ietf.org/html/rfc4288#section-4.2

   Type and subtype names MUST conform to the following ABNF:

       type-name = reg-name
       subtype-name = reg-name
       reg-name = 1*127reg-name-chars
       reg-name-chars = ALPHA / DIGIT / "!" /
                     "#" / "$" / "&" / "." /
                     "+" / "-" / "^" / "_"
   Note that this syntax is somewhat more restrictive than what is allowed by the ABNF in [RFC2045].
   In accordance with the rules specified in [RFC3023], media subtypes that do not represent XML entities
   MUST NOT be given a name that ends with the "+xml" suffix. More generally, "+suffix" constructs should be
   used with care, given the possibility of conflicts with future suffix definitions.
   While it is possible for a given media type to be assigned additional names,
   the use of different names to identify the same media type is discouraged.

   The "text" media type is intended for sending material that is principally textual in form.
   A "charset" parameter MAY be used to indicate the charset of the body text for "text" subtypes,
   notably including the subtype "text/plain", which is a generic subtype for plain text defined in [RFC2046].
   If defined, a text "charset" parameter MUST be used to specify a charset name
   defined in accordance to the procedures laid out in [RFC2978].

   A media type of "image" indicates that the content specifies or more separate images
   that require appropriate hardware to display.  The subtype names the specific image format.

   A media type of "audio" indicates that the content contains audio data.

   A media type of "video" indicates that the content specifies a time-varying-picture image,
   possibly with color and coordinated sound. The term 'video' is used in its most generic sense,
   rather than with reference to any particular technology or format,
   and is not meant to preclude subtypes such as animated drawings encoded compactly.
   Note that although in general this document strongly discourages the mixing of multiple media in a single body,
   it is recognized that many so-called video formats include a representation for synchronized audio and/or text,
   and this is explicitly permitted for subtypes of "video".

   The "application" media type is to be used for discrete data that do not fit in any of the media types,
   and particularly for data to be processed by some type of application program.
   This is information that must be processed by an application before it is viewable or usable by a user.
   Expected uses for the "application" media type include but are not limited to file transfer, spreadsheets,
   presentations, scheduling data, and languages for "active" (computational) material.
   (The latter, in particular, can pose security problems that must be understood by implementors,
   and are considered in detail in the discussion of the "application/ PostScript" media type in [RFC2046].)

   Multipart and message are composite types, that is, they provide a means of encapsulating zero or more objects,
   each labeled with its own media type.  All subtypes of multipart and message MUST conform to the syntax rules
   and other requirements specified in [RFC2046].

   Parameter names have the syntax as media type names and values:
          parameter-name = reg-name
   Note that this syntax is somewhat more restrictive than what is allowed
   by the ABNF in [RFC2045] and amended by [RFC2231].


 - RFC 4735 — https://tools.ietf.org/html/rfc4735

   From time to time, documents created by the IETF or by other standards bodies show
   examples involving the use of media types, where the actual media type is not relevant.
   It would be useful in such cases to be able to show a media type whose illustrative role in the example is clear.
   In the worst case, this can be useful to debug implementations where the designer
   mistook the example for a requirement of the protocol concerned.

   To meet this need, this document registers the following media types:
      -  the 'example' media type;
      -  the 'application/example', 'audio/example', 'image/example', 'message/example', 'model/example',
             'multipart/example', 'text/example', and 'video/example' media subtypes.
   It is suggested that compilers of illustrative examples involving media types in trees
   other than the standards tree might also incorporate the string "example" into their hypothetical media types.


 - RFC 6657 — https://tools.ietf.org/html/rfc6657#page-3
 
   In order to improve interoperability with deployed agents, "text/*" media type registrations SHOULD either
    a.  specify that the "charset" parameter is not used for the defined
        subtype, because the charset information is transported inside
        the payload (such as in "text/xml"), or
    b.  require explicit unconditional inclusion of the "charset"
        parameter, eliminating the need for a default value.
   Regardless of what approach is chosen, all new "text/*" registrations MUST clearly specify how the charset is determined;
   relying on the default defined in Section 4.1.2 of [RFC2046] is no longer permitted.
   However, existing "text/*" registrations that fail to specify how the charset is determined still default to US-ASCII.


 - RFC 6838 — https://tools.ietf.org/html/rfc6838#section-4.2

   Type and subtype names MUST conform to the following ABNF:

       type-name = restricted-name
       subtype-name = restricted-name
       restricted-name = restricted-name-first *126restricted-name-chars
       restricted-name-first  = ALPHA / DIGIT
       restricted-name-chars  = ALPHA / DIGIT / "!" / "#" /
                                "$" / "&" / "-" / "^" / "_"
       restricted-name-chars =/ "." ; Characters before first dot always
                                    ; specify a facet name
       restricted-name-chars =/ "+" ; Characters after last plus always
                                    ; specify a structured syntax suffix

   Note that this syntax is somewhat more restrictive than what is allowed by the ABNF in Section 5.1 of [RFC2045]
   or Section 4.2 of [RFC4288].  Also note that while this syntax allows names of up to 127 characters,
   implementation limits may make such long names problematic.
   For this reason, <type-name> and <subtype-name> SHOULD be limited to 64 characters.
   Although the name syntax treats "." as equivalent to any other character, characters before
   any initial "." always specify the registration facet.  Note that this means that
   facet-less standards-tree registrations cannot use periods in the subtype name.

   Similarly, the final "+" in a subtype name introduces a structured syntax specifier suffix.
   XML in MIME [RFC3023] defined the first such augmentation to the media type definition to additionally specify
   the underlying structure of that media type. That is, it specified a suffix (in that case, "+xml")
   to be appended to the base subtype name.  Since this was published, the de facto practice has arisen
   for using this suffix convention for other well-known structuring syntaxes.
   In particular, media types have been registered with suffixes such as "+der", "+fastinfoset", and "+json".
   This specification formalizes this practice and sets up a registry for structured type name suffixes.


 - RFC 7231 — https://datatracker.ietf.org/doc/html/rfc7231#section-3.1.1.1

   HTTP uses Internet media types [RFC2046] in the Content-Type
   (Section 3.1.1.5) and Accept (Section 5.3.2) header fields in order
   to provide open and extensible data typing and type negotiation.
   Media types define both a data format and various processing models:
   how to process that data in accordance with each context in which it
   is received.

     media-type = type "/" subtype *( OWS ";" OWS parameter )
     type       = token
     subtype    = token

   The type/subtype MAY be followed by parameters in the form of
   name=value pairs.

     parameter      = token "=" ( token / quoted-string )

   The type, subtype, and parameter name tokens are case-insensitive.
   Parameter values might or might not be case-sensitive, depending on
   the semantics of the parameter name.  The presence or absence of a
   parameter might be significant to the processing of a media-type,
   depending on its definition within the media type registry.

   A parameter value that matches the token production can be
   transmitted either as a token or within a quoted-string.  The quoted
   and unquoted values are equivalent.  For example, the following
   examples are all equivalent, but the first is preferred for
   consistency:

     text/html;charset=utf-8
     text/html;charset=UTF-8
     Text/HTML;Charset="utf-8"
     text/html; charset="utf-8"

   Internet media types ought to be registered with IANA according to
   the procedures defined in [BCP13].

      Note: Unlike some similar constructs in other header fields, media
      type parameters do not allow whitespace (even "bad" whitespace)
      around the "=" character.


 - RFC 8081 — https://tools.ietf.org/html/rfc8081

   This specification registers a new top-level type, "font", in the standards tree, adds it as an
   alternative value of "Type Name" in the media types registration form [Media-Type-Registration],
   and registers several subtypes for it.

   The "font" as the primary media content type indicates that the content identified by it
   requires a certain graphic subsystem such as a font rendering engine (and, in some cases,
   a text layout and a shaping engine) to process it as font data, which in turn may require
   a certain level of hardware capabilities such as certain levels of CPU performance and available memory.
   The "font" media type does not provide any specific information about the underlying data format and how the
   font information should be interpreted — the subtypes defined within a "font" tree name the specific font formats.
   Unrecognized subtypes of "font" should be treated as "application/octet-stream".
   Implementations may pass unrecognized subtypes to a common font-handling system, if such a system is available.

   Fragment identifiers for font collections identify one font in the collection
   by the PostScript name (name ID=6) [ISO.14496-22.2015]. This is a string, no longer than 63 characters
   and restricted to the printable ASCII subset, codes 33 ? 126, except for the 10 characters
   '[', ']', '(', ')', '{', '}', '<', '>', '/', '%', which are forbidden by [ISO.14496-22.2015].

   In addition, the following 6 characters could occur in the PostScript name but are
   forbidden in fragments by [RFC3986], and thus must be escaped: '"', '#', '\', '^', '`', '|'.

   If (following un-escaping) this string matches one of the PostScript names in the name table,
   that font is selected.  For example, "#Foo-Bold" refers to the font with PostScript name "Foo-Bold" and
   "#Caret%5Estick" refers to the font with PostScript name "Caret^stick".  If the name does not match,
   or if a fragment is not specified, the first font in the collection is matched.
   Note that the order of fonts in collections may change as the font is revised, so relying on a particular font
   in a collection always being first is unwise.

 - Unofficial: Chemical MIME Project — https://github.com/dleidert/chemical-mime

# Libraries?

 There are grammar parsing libraries for Ruby, but I'm not going to bother pulling in another dependency
 for a one-off and very-very-simple specification when compared to ABNF's full range of expressiveness.
 - http://www.a-k-r.org/abnf/ — https://github.com/akr/abnf
 - https://github.com/steveklabnik/abnf (Based on the above; gemified as https://rubygems.org/gems/abnf)
 - https://rubygems.org/gems/abnf-parser/ (Formerly https://github.com/ntl/abnf-parser but now MIA)
 - https://www.antlr.org/ — https://github.com/antlr/antlr4
 - https://gitlab.com/yorickpeterse/ruby-ll — https://rubygems.org/gems/ruby-ll/
 - Probably many more but you get the idea.
