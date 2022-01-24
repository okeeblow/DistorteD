require(-'pathname') unless defined?(::Pathname)

require_relative(-'../weighted_action') unless defined?(::CHECKING::YOU::OUT::WeightedAction)

module ::CHECKING::YOU::OUT::SweetSweet♥Magic
  # Represent one possible link in a chain of byte sequences for a successful content match.
  SequenceCat = ::Struct.new(:sequence, :boundary, :mask) do

    # In our source XML the `<magic>` element is the one that has the `priority` weight,
    # not the `<match>` element which this `Struct` represents, but this `Struct`
    # should support weighting too so we can avoid allocating a spurious weighted container
    # when it would contain only one member (us), in which case a non-default `weight`
    # will be moved from the container to here.
    include(::CHECKING::YOU::OUT::WeightedAction)

    # We get the raw sequence and the sequence format attributes in separate callbacks
    # due to the way Ox works, and I can't assume deterministric callback order.
    # Use one attr_writer for the sequence, one for the format, and store the intermediate value
    # directly in `self[:sequence]` so we don't allocate outside an RValue with instance vars.
    def sequence=(cat); self[:sequence] = self[:sequence].nil? ? cat : self[:sequence].call(cat); end
    def mask=(cat);     self[:mask]     = self[:mask].nil?     ? cat : self[:mask].call(cat);     end
    def mask;           self[:mask].is_a?(::Proc)              ? nil : self[:mask];               end
    def format=(format)
      self[:sequence] = self[:sequence].nil? ? format : format.call(self[:sequence])
      self[:mask]     = self[:mask].nil?     ? format : format.call(self[:mask])
    end

    # Represent our sequence as either a byte `::String` or as an `::Integer`.
    #
    # We'll need one or the other depending on if we have a mask or not, e.g.
    #   irb> ::CHECKING::YOU::OUT::from_iana_media_type('image/png').cat_sequence.sequence_s => "\x89PNG"
    #   irb> ::CHECKING::YOU::OUT::from_iana_media_type('image/png').cat_sequence.sequence_i => 2303741511
    #
    #   irb* ::XROSS::THE::CPU::swap(9894494448401390090).digits(0xFF.succ).each_with_object(::String::new) {
    #   irb*   _2.insert(-1, _1.chr(::Encoding::ASCII_8BIT))
    #   irb> } => "\x89PNG\r\n\x1A\n"
    def sequence_s = self[:sequence].is_a?(::String)  ?
      self[:sequence]                                 :
      self[:sequence].digits(0xFF.succ).each_with_object(::String::new) {
        _2.insert(-1, _1.chr(::Encoding::ASCII_8BIT))
      }
    def sequence_i = self[:sequence].is_a?(::Integer) ?
      self[:sequence]                                 :
      self[:sequence].each_char.reduce(0) { (_1 << 8) | _2.ord }

    # "The byte offset(s) in the file to check. This may be a single number or a range in the form `start:end',
    # indicating that all offsets in the range should be checked. The range is inclusive."
    def boundary=(range_string)
      return if range_string.nil?
      # I used to explicitly `String#split` on ':' here, but `#split` always allocates
      # even if it ends up splitting dedupable `String`s, so avoid it if possible.
      self[:boundary] = range_string.include?(-?:)      ?
        Range.new(*range_string.split(-?:).map(&:to_i)) :
        range_string.to_i
    end

    # Implement `Range`-like methods without necessarily having to allocate a new `Range`.
    #
    # Returns the beginning byte offset for where this sequence should be found in a hypothetical file/stream:
    def min
      case self[:boundary]
      when ::NilClass then 0
      when ::Integer  then self[:boundary]
      when ::Range    then self[:boundary].min
      else 0
      end
    end
    # Returns the end byte offset for where this sequence should be found in a hypothetical file/stream:
    def max
      case self[:boundary]
      when ::NilClass then self[:sequence].size
      when ::Integer  then self[:boundary] + self[:sequence].size
      when ::Range    then self[:boundary].max
      else self[:sequence].size
      end
    end
    # Returns both of the above:
    def minmax; [self.min, self.max]; end
    # …and the width in bytes of the possible search area.
    def size;    self.max - self.min; end

    # Match our embedded sequence against an arbitrary binary String.
    # The `offset` parameter isn't used here but needs to be defined so this `#=~`
    # and its custom `Array` container's `#=~` can be used interchangeably.
    def =~(otra, offset: 0)
      return case otra
      when ::NilClass then false
      when ::String then
        if self.mask.nil? or self.mask.eql?(0) then
          otra.include?(self.sequence_s)
        else
          # CorelDRAW! example, a RIFF format with "CDR<version-number>":
          #   irb> "CDRXvrsn".each_char.reduce(0) { (_1 << 8) | _2.ord } & 0xffffff00ffffffff => 4847089260898186094
          #   irb> "CDR5vrsn".each_char.reduce(0) { (_1 << 8) | _2.ord } & 0xffffff00ffffffff => 4847089260898186094
          #   irb> "CDR3vrsn".each_char.reduce(0) { (_1 << 8) | _2.ord } & 0xffffff00ffffffff => 4847089260898186094
          (otra[0...self[:sequence].size].each_char.reduce(0) { (_1 << 8) | _2.ord } & self.mask).eql?(
            (self.sequence_i & self.mask)
          )
        end
      when ::Integer then
        otra.eql?(
          (self.mask.nil? or self.mask.eql?(0)) ?
            self.sequence_i                     :
            (self.sequence_i & self.mask)
        )
      when ::IO then
        otra.seek(self.min, whence=IO::SEEK_SET)
        self.=~(otra.read(self.size), offset: offset)
      else false
      end
    end

  end  # SequenceCat
end
