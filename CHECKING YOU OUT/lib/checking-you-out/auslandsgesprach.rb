
# https://github.com/jarib/ffi-xattr
require 'ffi-xattr'


module CHECKING; end
class CHECKING::YOU; end
module CHECKING::YOU::IN::AUSLANDSGESPRÄCH

  # Parse IETF Media-Type String → `::CHECKING::YOU::IN`
  FROM_IETF_TYPE = proc {
    # Keep these allocated instead of fragmenting our heap, since this will be called very frequently.
    scratch = Array.allocate
    hold = Array.allocate
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

    # Take a single codepoint from a reversed-then-NULL-terminated IETF Type String,
    # e.g. "ttub=traf;lmbe+fnb.ppg3.dnv/noitacilppa#{-?\u{0}}".
    #
    # I switched from `String#each_char` to `String#each_codepoint` to avoid allocating single-character Strings
    # before they could be deduplicated with `-zig`. The Integer codepoints, on the other hand,
    # will always be the same `object_id` for the same codepoint:
    #
    # rb(main):162:0> -"あああ".each_char { |c| p c.object_id }
    # 420
    # 440
    # 460
    #
    # rb(main):163:0> -"あああ".each_codepoint { |c| p c.object_id }
    # 4709
    # 4709
    # 4709
    move_zig = proc { |zig|
      case zig
      when 0 then  # NULL
        my_base[:phylum] = -scratch.reverse!.pack(-'U*')
      when 61 then  # =
        hold.push(*scratch.reverse!)
      when 59 then  # ;
        scratch.clear
        hold.clear
      when 43 then  # +
        scratch.clear
      when 47 then  # /
        my_base[:kingdom] = case
        when scratch[..2] == (-'dnv').codepoints then
          scratch.unshift(3); hold.rindex(46) ? -hold[hold.rindex(46)+1..].pack(-'U*') : -'vnd'
        when scratch[..2] == (-'srp').codepoints then
          scratch.unshift(3); -'prs'
        when scratch[..4] == (-'-sm-x').codepoints then
          scratch.unshift(5); -'x-ms'
        when scratch[..1] == (-'-x').codepoints then
          scratch.unshift(2); -?x
        when scratch.one? && scratch.last == 100 then  # x
          scratch.pop; -'kayo-dot'
        else -'possum'
        end
        hold << 46 unless hold.empty? or scratch.empty?
        hold.push(*scratch.reverse!)
        my_base[:genus]= -hold.pack(-'U*')
        scratch.clear
        hold.clear
      when 46 then  # .
        hold << 46 unless hold.empty? or scratch.empty?
        hold.push(*scratch.reverse!)
        scratch.clear
      else
        scratch << zig
      end
    }

    # 𝘐𝘛'𝘚 𝘠𝘖𝘜 !!
    cats = ->(gentlemen) {
      gentlemen.reverse!.<<(-?\u{0}).each_codepoint(&move_zig)
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
    # Note: Explicitly calling `-''` for now until I confirm the behavior of `NilClass#to_s` in Ruby 3.0+.
    # In Ruby 2.7 `nil.to_s` will return a deduplicated immutable empty String: https://bugs.ruby-lang.org/issues/16150
    # added experimentally in https://github.com/ruby/ruby/commit/6ffc045a817fbdf04a6945d3c260b55b0fa1fd1e
    # but then reverted in https://github.com/ruby/ruby/commit/bea322a352d820007dd4e6cab88af5de01854736
    -(String.allocate << self.phylum << -'/' << case
    when self.kingdom == -'kayo-dot' then -'x.'
    when self.kingdom == -?x then -'x-'
    when self.kingdom == -'x-ms' then -'x-ms-'
    when self.kingdom == -'prs' then -'prs.'
    when self.kingdom == -'vnd' then -'vnd.'
    when self.kingdom == -'possum' then -''
    when !IETF_TREES.include?(self.kingdom) then 'vnd.' << self.kingdom << -'.'
    else self.kingdom << -'.'
    end << self.genus)
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
