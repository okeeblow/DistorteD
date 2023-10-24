# Microsoft-style GUID components.
module ::GlobeGlitter::ALIEN_TEMPLE

  # Auto-detect Microsoft-style `layout` given certain known GUID ranges.
  #
  # "`DATA4`" here refers to the second 64 bits in a 128-bit GUID, i.e. it has a *different layout of bits*
  # compared to ITU/RFC-style 128-bit UUIDs: https://learn.microsoft.com/en-us/windows/win32/api/guiddef/ns-guiddef-guid
  #
  # A GUID's `DATA4` is often expressed in Windows-land as an `::Array` of eight bytes as a sidestep around endianness.
  # All components of a GUID are little-endian, but any single byte is the same in either endianness,
  # so an `::Array` of eight little-endian bytes is effectively the same thing as a big-endian 64-bit value.
  # This is why many sources describe MS-style GUIDs as mixed-endian.
  KNOWN_MICROSOFT_DATA4 = [

    # COM/OLE CLSIDs.
    #
    # `ole2spec.doc` https://archive.org/details/MSDN_Operating_Systems_SDKs_Tools_October_1996_Disc_2
    # shows the example CLSID `{12345678-9ABC-DEF0-C000-000000000046}`, indicating the variable and constant parts.
    #
    # These CLSIDs are (AFAICT) the reason for ITU-T Rec. X.667 / RFC 4122's "Microsoft backwards-compatibility" variant.
    # Note the leading `0xC` byte of CLSIDs' `DATA4`, the same byte that marks the `variant` in the ITU/RFC layout,
    # with the same value as the "0b110x" MS variant:  irb> 0b11000000.chr => "\xC0"
    # https://github.com/libyal/libfwsi/blob/main/documentation/Windows%20Shell%20Item%20format.asciidoc#88-class-identifiers
    # http://justsolve.archiveteam.org/wiki/Microsoft_Compound_File#Root_storage_object_CLSIDs
    0xC000000000000046,

    # DirectShow codec GUIDs.
    #
    # The generic form of `XXXXXXXX-0000-0010-8000-00AA00389B71` is given on
    # https://learn.microsoft.com/en-us/windows/win32/directshow/fourccmap
    #
    # As I write this, https://gix.github.io/media-types/ has 684 matches for "8000-00AA00389B71".
    #
    # The "8000-00AA00389B71" `DATA4` could be still more accurately matched by also looking for
    # little-endian 0x0010 `DATA3` and 0x0 `DATA2`, but just matching the `DATA4` seems unique enough
    # and I don't feel like making this more complicated right now lol
    0x800000AA00389B71,

  ]  # KNOWN_MICROSOFT_DATA4


  # https://learn.microsoft.com/en-us/windows/win32/api/guiddef/ns-guiddef-guid sez —
  #
  #  “A GUID is a 128-bit value consisting of one group of 8 hexadecimal digits, followed by three groups
  #   of 4 hexadecimal digits each, followed by one group of 12 hexadecimal digits. The following example GUID
  #   shows the groupings of hexadecimal digits in a GUID: `6B29FC40-CA47-1067-B31D-00DD010662DA`.”
  #
  #   `typedef struct _GUID {
  #      unsigned long  Data1;
  #      unsigned short Data2;
  #      unsigned short Data3;
  #      unsigned char Data4[8];
  #    } GUID;`
  #
  #  “The first 2 bytes [of `Data4`] contain the third group of 4 hexadecimal digits.
  #   The remaining 6 bytes contain the final 12 hexadecimal digits.”
  #
  # GUID structure is often described as "mixed-endian", but that's confusing IMO.
  # Think of the entire thing as little-endian, but the data4 array of eight octets
  # is the same in either endianness.
  def data1 = self.layout.eql?(self.class::LAYOUT_MICROSOFT) ?
              ::XROSS::THE::CPU::swap32(self.bits127–96)     : self.bits127–96
  def data2 = self.layout.eql?(self.class::LAYOUT_MICROSOFT) ?
              ::XROSS::THE::CPU::swap32(self.bits95–80)      : self.bits95–80
  def data3 = self.layout.eql?(self.class::LAYOUT_MICROSOFT) ?
              ::XROSS::THE::CPU::swap32(self.bits79–64)      : self.bits79–64
  def data4 = 8.times.with_object(self.bits63–0).with_object(::Array::new) { |(which, sixtyfour), out|
    out.unshift((sixtyfour >> (which * 8) & 0xFF))
  }

  def replace_data1(otra) = self.replace_bits127–96(
    self.layout.eql?(self.class::LAYOUT_MICROSOFT) ? ::XROSS::THE::CPU::swap32(otra) : otra
  )
  def replace_data2(otra) = self.replace_bits95–80(
    self.layout.eql?(self.class::LAYOUT_MICROSOFT) ? ::XROSS::THE::CPU::swap16(otra) : otra
  )
  def replace_data3(otra) = self.replace_bits79–64(
    self.layout.eql?(self.class::LAYOUT_MICROSOFT) ? ::XROSS::THE::CPU::swap16(otra) : otra
  )
  def replace_data4(otra) = self.replace_bits63–0(
    otra.reduce { (_1 << 8) | _2 }
  )

  def with_data1(otra) = self.with(inner_spirit: self.replace_data1(otra))
  def with_data2(otra) = self.with(inner_spirit: self.replace_data2(otra))
  def with_data3(otra) = self.with(inner_spirit: self.replace_data3(otra))
  def with_data4(otra) = self.with(inner_spirit: self.replace_data4(otra))

end
