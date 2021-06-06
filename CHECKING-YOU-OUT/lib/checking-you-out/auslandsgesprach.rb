
# https://github.com/jarib/ffi-xattr
require 'ffi-xattr'


module CHECKING; end
class CHECKING::YOU; end
module CHECKING::YOU::IN::AUSLANDSGESPRÄCH

  # IETF Media-Type String parser.
  #
  # TOD0: There are probably gainz to be had here. Profile more and find out.
  #       Maybe I should freeze CYI keys instead of Symbolizing?
  #       https://samsaffron.com/archive/2018/02/16/reducing-string-duplication-in-ruby
  #       https://bugs.ruby-lang.org/issues/13077
  #       https://rubytalk.org/t/psa-string-memory-use-reduction-techniques/74477
  FROM_IETF_TYPE = proc {
    # Keep these allocated instead of fragmenting our heap, since this will be called very frequently.
    scratch = String.allocate
    hold = String.allocate
    my_base = ::CHECKING::YOU::IN::allocate

    # Clear out the contents of the above temporary vars,
    # called to ensure we never leak the contents of one parse into another.
    the_bomb = proc {
      scratch.clear
      hold.clear
      my_base.members.each { |gentleman|
        my_base[gentleman] = nil
      }
    }

    # Take a single popped character from a reversed IETF Type String,
    # e.g. "ttub=traf;lmbe+fnb.ppg3.dnv/noitacilppa".
    move_zig = proc { |zig|
      case zig
      when -?\u{0} then
        my_base[:phylum] = scratch.reverse!.to_sym
      when -?= then
        scratch.each_char.reverse_each.reduce(hold, :<<)
      when -?; then
        scratch.clear
        hold.clear
      when -?+ then
        scratch.clear
      when -?/ then
        my_base[:kingdom] = case
        when scratch.delete_prefix!(-'dnv') then
          File.extname(hold).empty? ? :vnd : hold.slice!((File.extname(hold).length * -1)..)[1..]
        when scratch.delete_prefix!(-'srp') then :prs
        when scratch.delete_suffix!(-'-sm-x') then :"x-ms"
        when scratch.delete_suffix!(-'-x') then :x
        when scratch.length == 1 && scratch.delete_suffix!(-'x') then :"kayo-dot"
        else :possum
        end&.to_sym
        hold << -?. unless hold.empty? or scratch.empty?
        my_base[:genus] = scratch.each_char.reverse_each.reduce(hold, :<<).to_sym
        scratch.clear
        hold.clear
      when -'.' then
        hold << -?. unless hold.empty? or scratch.empty?
        scratch.each_char.reverse_each.reduce(hold, :<<)
        scratch.clear
      else
        scratch << zig
      end
    }

    # 𝘐𝘛'𝘚 𝘠𝘖𝘜 !!
    cats = ->(gentlemen) {
      gentlemen.reverse!.<<(-?\u{0}).each_char(&move_zig)
      return my_base.dup.tap(&the_bomb)
    }
    -> (gentlemen) {
      return cats.call(gentlemen)
    }
  }.call

  # Call the above singleton Proc to do the thing.
  def from_ietf_media_type(ietf_string)
    return if ietf_string.nil?
    FROM_IETF_TYPE.call(ietf_string)
  end
end

module CHECKING::YOU::IN::INLANDSGESPRÄCH
  # Non-IETF-tree as a CY(I|O)'s `kingdom` signifies the need for a leading `vnd.` facet
  # when reconstructing the Media-Type String.
  IETF_TREES = [
    # Current top-level registries are shown here: https://www.iana.org/assignments/media-types/media-types.xhtml
    # The latest addition reflected here is `font` from RFC 8081: https://datatracker.ietf.org/doc/html/rfc8081
    -'application',
    -'audio',
    -'example',
    -'font',
    -'image',
    -'message',
    -'model',
    -'multipart',
    -'text',
    -'video',
  ]

  # Reconstruct an IETF Media-Type String from a loaded CYI/CYO's `#members`
  def to_s
    # TODO: Fragments (e.g. `;what=ever`), and syntax identifiers (e.g. `+xml`)
    self.phylum&.to_s << '/'.freeze << case
    when self.kingdom == :"kayo-dot" then 'x.'.freeze
    when self.kingdom == :x then 'x-'.freeze
    when self.kingdom == :"x-ms" then 'x-ms-'.freeze
    when self.kingdom == :prs then 'prs.'.freeze
    when self.kingdom == :vnd then 'vnd.'.freeze
    when self.kingdom == :possum then nil.to_s
    when !IETF_TREES.include?(self.kingdom) then 'vnd.' << self.kingdom.to_s << '.'
    else self.kingdom.to_s << '.'
    end << self.genus.to_s
  end

  # Pretty-print objects using our custom `#:to_s`
  def inspect
    "#<#{self.class.to_s} #{self.to_s}>"
  end
end

module CHECKING::YOU::OUT::AUSLANDSGESPRÄCH

  def from_ietf_media_type(ietf_string)
    return if ietf_string.nil?
    self.new(super)
  end

  # CHECK OUT a filesystem path.
  # This might be a String, or might be an instance of the actual stdlib class `Pathname`:
  # https://ruby-doc.org/stdlib/libdoc/pathname/rdoc/Pathname.html
  def from_pathname(pathname)
    # T0DO: Handle relative paths and all the other corner cases that could be here when given String.

    # Check the filesystem extended attributes for manually-defined types.
    #
    # The freedesktop-dot-org specification is `user.mime_type`:
    # https://www.freedesktop.org/wiki/CommonExtendedAttributes/
    #
    # At least one other application I can find (lighttpd a.k.a. "lighty")
    # will use `Content-Type` just like would be found in an HTTP header:
    # https://redmine.lighttpd.net/projects/1/wiki/Mimetype_use-xattrDetails
    #
    # Both of these should contain IETF-style `media/sub`-type Strings,
    # but they are technically freeform and must be assumed to contain anything.
    # It's very very unlikely that anybody will ever use one of these at all,
    # but hey how cool is it that we will support it if they do? :)
    #
    # T0DO: Figure out if NTFS has anything to offer us since `ffi-xattr` does support Winders.
    # https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-fscc/a82e9105-2405-4e37-b2c3-28c773902d85
    from_ietf_media_type(
      Xattr.new(pathname).to_h.slice('user.mime_type', 'Content-Type').values.first
    )
  end

end
