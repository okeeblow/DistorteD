require 'set'

## Adds better support to Ruby's Encoding class for IBM/Microsoft-style numeric codepage IDs:
#  - Adds a `:code_page` method on any instance of Encoding, returning the Integer codepage ID.
#  - Adds a `:page_code` singleton method on :Encoding, returning the Encoding instance for any Integer codepage ID.
#  - Patches Encoding::find() to add Integer and numeric-String find() support using :page_code.
#  - Adds a `:code_page_orphans` singleton method on :Encoding, returning a Set of built-in Encodings that
#    do not have a corresponding built-in `:CP<####>` name/constant.
#  - Includes many additional numeric codepage IDs based on information
#    from IANA, Unicode Consortium, OS vendors, and some of my own speculation.

## This is similar in effect (but not in implementation) to the 'encoding-codepage' Gem:
#   https://github.com/ConradIrwin/encoding-codepage
# My choice of method name `:code_page` was intentional to avoid conflict with this Gem's `:codepage`.


## Notes-To-Self about Encoding (the class I'm patching) and encodings in general:

##  Unicode Normalization Forms
#
# - Canonical composed (NFC) and decomposed (NFD) forms.
# - Non-canonical composed (NFKC) and decomposed (NFKD) forms.
#
# "For example, form C uses the single Unicode code point "Ä" (U+00C4),
# while form D uses ("A" + "¨", that is U+0041 U+0308).
# These render identically, because "¨" (U+0308) is a combining character."
#
# http://www.unicode.org/faq/normalization.html
# http://www.unicode.org/reports/tr15/
# https://docs.microsoft.com/en-us/windows/win32/intl/using-unicode-normalization-to-represent-strings
# https://en.wikipedia.org/wiki/Precomposed_character
# https://en.wikipedia.org/wiki/Unicode_equivalence
#
# HFS+ is a notable outlier among filesystems by requiring decomposed form (actually 'UTF-8-Mac' variant).

## Ruby includes a lot of the desired codepoint ID data built-in,
# but in the form of String alias names for Encoding instances,
#  e.g. KOI8-R is also codepage 878:
# 
# irb> Encoding::KOI8_R.names
#   => ["KOI8-R", "CP878"]
# 
# irb> Encoding::KOI8_R.names.any?{ |n| n =~ /^(CP|IBM|Windows[-_])(?<code_page>\d{3,}$)/ }
#   => true
# irb> Regexp.last_match
#   => #<MatchData "CP878" code_page:"878">
#
# My code defers to this built-in data where possible instead of doing
# a complete import of the Microsoft identifiers like the Gem.
  

## Some encodings have both generic and vendor-prefixed names,
## and some are canonically one or the other, e.g.:
#
# irb> Encoding::IBM437
#   => #<Encoding:IBM437>
# irb> Encoding::CP437
#   => #<Encoding:IBM437>
#
# irb> Encoding::IBM850
#   => #<Encoding:CP850>
# irb> Encoding::CP850
#   => #<Encoding:CP850>


class Encoding

  # Define a Regexp to match and extract Ruby's built-in numeric codepage IDs
  # from thir Encoding's names.
  #
  # Using IGNORECASE to handle the duplicate differing-capitalization constants,
  # e.g. Encoding::WINDOWS_31J and Encoding::Windows_31J both exist and are equivalent.
  #
  # Worth mentioning since this file deals with Encoding,
  # but the Regexp itself also has an internal Encoding that can be changed
  # if I had any reason to (I don't):
  # https://ruby-doc.org/core/Regexp.html#class-Regexp-label-Encoding
  CODE_PAGE_ENCODING_NAME = Regexp.new('^(CP|IBM|Windows[-_])(?<code_page>\d{3,}$)', Regexp::IGNORECASE)

  # Data sources:
  # https://www.aivosto.com/articles/charsets-codepages.html
  # https://developer.apple.com/documentation/coreservices/1400434-ms-dos_and_windows_text_encodings
  # https://docs.microsoft.com/en-us/windows/win32/intl/code-page-identifiers
  # https://en.wikipedia.org/wiki/CCSID
  # https://github.com/SheetJS/js-codepage/blob/master/codepage.md
  ADDITIONAL_ENCODING_CODE_PAGE_IDS = {

    # Burgerland :911:
    Encoding::US_ASCII => 20127,

    # Unicode
    Encoding::UTF_16LE => 1200,
    Encoding::UTF_16BE => 1201,
    Encoding::UTF_32LE => 12000,
    Encoding::UTF_32BE => 12001,

    ## 245
    #
    # Code Page 932 is Windows-31J, but I want to provide fallback mapping
    # between 932 and Shift_JIS to handle detected-text or `encoding` arguments
    # that return Shift_JIS since that naming is much much more well-known than 31J.
    Encoding::SHIFT_JIS => 932,
    # https://referencesource.microsoft.com/#mscorlib/system/text/eucjpencoding.cs
    # https://www.redmine.org/issues/29442
    # https://www.sljfaq.org/afaq/encodings.html
    # https://uic.jp/charset/
    # http://www.monyo.com/technical/samba/docs/Japanese-HOWTO-3.0.en.txt
    Encoding::EUC_JP_MS => 20932,
    Encoding::EUC_JP => 51932,
    # Encoding:EUC-JIS-2004 dunno
    #
    # https://www.debian.org/doc/manuals/intro-i18n/ch-coding.en.html  3.2: Stateless and Stateful
    # TL;DR: Stateful uses an escape sequence to switch charset;
    #        Stateless have all-unique codepoints.
    #        Normal ISO-2022-JP is stateful.
    # "For example, in ISO 2022-JP, two bytes of 0x24 0x2c may mean a Japanese Hiragana character 'が'
    #  or two ASCII character of '$' and ',' according to the shift state."
    # Encoding::STATELESS_ISO_2022_JP
    #
    # Mobile operator specific encodings that I have no numeric IDs for rn:
    # Encoding:UTF8-DoCoMo
    # Encoding:SJIS-DoCoMo
    # Encoding:UTF8-KDDI
    # Encoding:SJIS-KDDI
    # Encoding:stateless-ISO-2022-JP-KDDI
    # Encoding:UTF8-SoftBank
    # Encoding:SJIS-SoftBank

    ## CHY-NAH
    #
    # https://en.wikipedia.org/wiki/Code_page_903
    Encoding::GB1988 => 903,
    #
    ## Hong Kong Supplementary Character Set
    # The Windows version of this seems to be the built-in CP951:
    # https://web.archive.org/web/20160402215421/https://blogs.msdn.microsoft.com/shawnste/2007/03/12/cp-951-hkscs/
    # https://web.archive.org/web/20141129233053/http://www-01.ibm.com/software/globalization/ccsid/ccsid5471.html
    Encoding::BIG5_HKSCS => 5417,
    #
    # The 936 postfix is a reference to the standard Windows Chinese encoding being CP936 / GBK.
    # "GB2312 is the registered internet name for EUC-CN, which is its usual encoded form."
    Encoding::GB2312 => 20936,
    Encoding::GB12345 => 51936,
    #Encoding:GB2312_HZ => 52936,  # Doesn't exist in Ruby
    Encoding::GB18030 => 54936,


    ## Asia At Odd Hours
    #
    # I always wondered if the "Gravitational Pull of Pepsi" logo came from
    # them wanting it to look less like the Korean flag.
    # The traditional Korean Windows Code Page is CP949, available in Ruby
    # but not under any other name aliases.
    # IBM uses CP1363, not in Ruby.
    Encoding::EUC_KR => 51949,
    #
    # ROC me now
    Encoding::EUC_TW => 51950,
    # Unicode 補完計畫 / Unicode-At-On is a Big5 variant once popular in Taiwan:
    # https://lists.gnu.org/archive/html/bug-gnu-libiconv/2010-11/msg00007.html
    # https://lists.w3.org/Archives/Public/public-html-ig-zh/2012Apr/0061.html
    # Encoding::BIG5_UAO
    #
    # CP950 (available in Ruby) is the code page used on Windows under the name "big5',
    # but I want to map the generic Big5 Encoding to 950 as well to handle
    # detected and specified encodings by that name.
    # "The major difference between Windows code page 950 and "common" (non-vendor-specific) Big5
    #  is the incorporation of a subset of the ETEN extensions to Big5 at 0xF9D6 through 0xF9FE
    #  (comprising the seven Chinese characters 碁, 銹, 裏, 墻, 恒, 粧, and 嫺,
    #  followed by 34 box drawing characters and block elements)."
    Encoding::Big5 => 950,
    #
    # Encoding::TIS_620 is the base Thai 8-bit encoding standard that is apparently
    # never actually used in the wild.
    # ISO-8859-11 is identical to it with the sole exception "that ISO/IEC 8859-11
    # allocates non-breaking space to code 0xA0, while TIS-620 leaves it undefined."
    # "The Microsoft Windows code page 874 as well as the code page used in the
    #  Thai version of the Apple Macintosh, MacThai,
    #  are variants of TIS-620 — incompatible with each other, however."


    # Eastern Yurp
    #Encoding::KOI8_R => 20866,
    Encoding::KOI8_U => 21866,

    ## ISO/IEC 8859 (8-bit) encoding family
    #
    Encoding::ISO_8859_1 => 28591,  # West European languages (Latin-1)
    Encoding::ISO_8859_2 => 28592,  # Central and East European languages (Latin-2)
    Encoding::ISO_8859_3 => 28593,  # Southeast European and miscellaneous languages (Latin-3)
    Encoding::ISO_8859_4 => 28594,  # Scandinavian/Baltic languages (Latin-4)
    Encoding::ISO_8859_5 => 28595,  # Latin/Cyrillic
    Encoding::ISO_8859_6 => 28596,  # Latin/Arabic
    Encoding::ISO_8859_7 => 28597,  # Latin/Greek
    Encoding::ISO_8859_8 => 28598,  # Latin/Hebrew
    Encoding::ISO_8859_9 => 28599,  # Latin-1 modification for Turkish (Latin-5)
    #
    # ISO-8859-10 covers Nordic languages better than ISO_8859_4.
    # Wikipedia says this has been assigned in Windows as 28600 even though Microsoft's
    # page doesn't list it now in 2020, but w/e.
    # IBM assigned it as CP919.
    Encoding::ISO_8859_10 => 28600,  # Lappish/Nordic/Eskimo languages (Latin-6)
    #
    # Wikipedia says this is assigned, but same deal.
    Encoding::ISO_8859_11 => 28601,  # Latin/Thai
    #
    # Intended Celtic encoding abandoned in 1997 in favor of ISO_8859_14:
    # Encoding::ISO_8859_12 => 28602,
    #
    Encoding::ISO_8859_13 => 28603,  # Baltic Rim languages (Latin-7)
    Encoding::ISO_8859_14 => 28604,  # Celtic (Latin-8)
    Encoding::ISO_8859_15 => 28605,  # West European languages (Latin-9)
    Encoding::ISO_8859_16 => 28606,  # Romanian (Latin-10)

    # Apple encodings
    #
    # UTF8_MAC is the encoding Mac OS X uses on HFS+ filesystems and is a variant of UTF-8-NFD.
    # https://web.archive.org/web/20140812023313/http://developer.apple.com/library/ios/documentation/MacOSX/Conceptual/BPInternational/Articles/FileEncodings.html
    # "Mac OS Extended (HFS+) uses canonically decomposed Unicode 3.2 in UTF-16 format,
    #  which consists of a sequence of 16-bit codes.
    #  (Characters in the ranges U2000-U2FFF, UF900-UFA6A, and U2F800-U2FA1D are not decomposed.)"
    #
    # There isn't a good Microsoft-style ID I can assign to it, so this is just FYI.

    # Classic Mac encodings
    #
    # https://en.wikipedia.org/wiki/Category:Mac_OS_character_encodings
    # http://mirror.informatimago.com/next/developer.apple.com/documentation/macos8/TextIntlSvcs/TextEncodingConversionManager/TEC1.5/TEC.1b.html
    #
    # MacRoman pre-OS-8.5 has the "Universal currency symbol" at 0xDB,
    # while 8.5 and later replace it with the (then-new) Euro symbol:
    #   https://en.wikipedia.org/wiki/Currency_sign_(typography)
    Encoding::MACROMAN => 10000,
    #
    # "Shift-JIS with JIS Roman modifications, extra 1-byte characters, 2-byte Apple extensions,
    #  and some vertical presentation forms in the range 0xEB40--0xEDFE ("ku plus 84")."
    #  Ruby also defines Encoding::MACJAPAN but it's the same Encoding.
    Encoding::MACJAPANESE => 10001,
    #
    # The following encodings are not defined in Ruby's Encoding class,
    # but I'm listing them here for completeness' sake.
    # MACCHINESETRAD => 10002,
    # MACKOREAN => 10003,
    # MACARABIC => 10004,
    # MACHEBREW => 10005,
    # MACGREEK => 10006,
    # MACCYRILLIC => 10007,
    # MACHINESESIMP => 10008,
    #
    # Unlike MacJapan/MacJapanese, MacRomania is something different than MacRoman.
    Encoding::MACROMANIA => 10010,
    #
    Encoding::MACUKRAINE => 10017,
    Encoding::MACTHAI => 10021,
    Encoding::MACCENTEURO => 10029,
    Encoding::MACICELAND => 10079,
    Encoding::MACTURKISH => 10081,
    Encoding::MACCROATIAN => 10082,

  }  # ADDITIONAL_ENCODING_CODE_PAGE_IDS

  # Returns a Hash of the built-in-orphan Encodings we now have codepage IDs for,
  # e.g. {#<Encoding:US-ASCII>=>20127, #<Encoding:UTF-16BE>=>1201, #<Encoding:UTF-16LE>=>1200}
  def self.adopted_encoding_code_page_ids
    @@adopted_encoding_code_page_ids ||= self::code_page_orphans.select{ |e|
      if self::ADDITIONAL_ENCODING_CODE_PAGE_IDS.has_key?(e)
        # irb> Encoding.const_defined?('CP932')
        # => true  
        not Encoding::const_defined?("CP#{self::ADDITIONAL_ENCODING_CODE_PAGE_IDS[e]}")
      else
        false
      end
    }.map{ |e|
      [e, self::ADDITIONAL_ENCODING_CODE_PAGE_IDS[e]]
    }.to_h
  end

  # Returns a Set of built-in Encodings whose :names /!\ DO NOT /!\ contain a usable
  # numeric codepage ID, as matched by our Regexp.
  def self.code_page_orphans
    Encoding.list.select{ |c|
      c.respond_to?(:names) ? (not c.names.any?{|n| CODE_PAGE_ENCODING_NAME.match(n)}) : false
    }.to_set
  end

  # Returns the Encoding instance of any Integer codepage ID.
  def self.page_code(code_page_id)
    # Every canonically-Windows*/IBM*-named Encoding seems to also have a 'CP<whatever>' equivalent.
    Encoding::find("CP#{code_page_id}") rescue nil
  end

  # Returns the Integer codepage ID of any Encoding instance.
  def code_page
    Encoding::adopted_encoding_code_page_ids.fetch(
      self,
      self.names.any?{ |n| CODE_PAGE_ENCODING_NAME.match(n) } ? Regexp.last_match['code_page'.freeze].to_i : nil
    )
  end

  # Patch the Encoding::find() method to support taking Integer and numeric-String arguments
  # in addition to the Symbol and canonical-String args it usually supports.
  find_you_again = singleton_method(:find)
  define_singleton_method(:find) do |code_page_id|
    begin
      if code_page_id.is_a?(Integer)
        Encoding::page_code(code_page_id)
      elsif code_page_id.to_i > 0
        # String#to_i returns 0 for any non-entirely-numeric String
        Encoding::page_code(code_page_id.to_i)
      else
        find_you_again.(code_page_id)
      end
    rescue RuntimeError => e
      find_you_again.(code_page_id)
    end
  end

end
