
module CHECKING; end
class CHECKING::YOU; end
module CHECKING::YOU::AUSLANDSGESPRÄCH

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
      when '='.freeze then
        scratch.each_char.reverse_each.reduce(hold, :<<)
      when ';'.freeze then
        scratch.clear
        hold.clear
      when '+'.freeze then
        scratch.clear
      when '/'.freeze then
        my_base[:kingdom] = case
        when scratch.delete_prefix!('dnv'.freeze) then
          File.extname(hold).empty? ? :vnd : hold.slice!((File.extname(hold).length * -1)..)[1..]
        when scratch.delete_prefix!('srp'.freeze) then :prs
        when scratch.delete_suffix!('-sm-x'.freeze) then :"x-ms"
        when scratch.delete_suffix!('-x'.freeze) then :x
        when scratch.delete_suffix!('.x'.freeze) then :"kayo-dot"
        else :possum
        end&.to_sym
        hold << '.'.freeze unless hold.empty? or scratch.empty?
        my_base[:genus] = scratch.each_char.reverse_each.reduce(hold, :<<).to_sym
        scratch.clear
        hold.clear
      when '.'.freeze then
        hold << '.'.freeze unless hold.empty? or scratch.empty?
        scratch.each_char.reverse_each.reduce(hold, :<<)
        scratch.clear
      else
        scratch << zig
      end
    }

    # 𝘐𝘛'𝘚 𝘠𝘖𝘜 !!
    cats = ->(gentlemen) {
      gentlemen.each_char.reverse_each(&move_zig)
      my_base[:phylum] = scratch.each_char.reverse_each.reduce(:<<).to_sym
      return my_base.dup.tap(&the_bomb)
    }
    -> (gentlemen) {
      return ::CHECKING::YOU::OUT::new(cats.call(gentlemen))
    }
  }.call

  # Call the above singleton Proc to do the thing.
  def from_ietf_media_type(ietf_string)
    return if ietf_string.nil?
    FROM_IETF_TYPE.call(ietf_string)
  end


end
