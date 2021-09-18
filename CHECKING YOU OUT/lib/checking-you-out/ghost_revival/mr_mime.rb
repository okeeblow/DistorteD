require(-'ox') unless defined?(::Ox)

# Pre-evolution handler that provides all of the helper methods this handler needs to work.
require_relative(-'mime_jr') unless defined?(::CHECKING::YOU::OUT::MIMEjr)


# Push-event-based parser for freedesktop-dot-org `shared-mime-info`-format XML package files,
# including the main `shared-mime-info` database itself (GPLv2+), Apache Tika (MIT), and our own (AGPLv3).
# https://specifications.freedesktop.org/shared-mime-info-spec/shared-mime-info-spec-latest.html
# https://gitlab.freedesktop.org/xdg/shared-mime-info/-/blob/master/src/update-mime-database.c
#
#
# Example pulled from `freedesktop.org.xml.in`:
#
#   <mime-type type="application/vnd.oasis.opendocument.text">
#     <comment>ODT document</comment>
#     <acronym>ODT</acronym>
#     <expanded-acronym>OpenDocument Text</expanded-acronym>
#     <sub-class-of type="application/zip"/>
#     <generic-icon name="x-office-document"/>
#     <magic priority="70">
#       <match type="string" value="PK\003\004" offset="0">
#         <match type="string" value="mimetype" offset="30">
#           <match type="string" value="application/vnd.oasis.opendocument.text" offset="38"/>
#         </match>
#       </match>
#     </magic>
#     <glob pattern="*.odt"/>
#   </mime-type>
#
# This evolved handler builds "full" `CYO` objects matching a given `CYI`/`String`/`Regexp` key.
# "Full" in this case means composed of all related data spread across all enabled XML packages.
class ::CHECKING::YOU::OUT::MrMIME < ::CHECKING::YOU::OUT::MIMEjr

  # `MrMIME::new` will take any of these keys as keyword arguments
  # whose value will override the default defined in this Hash.
  DEFAULT_LOADS = {
    :textual_metadata => true,
    :host_metadata => false,
    :pathname_match => true,
    :content_match => true,
    :family_tree => true,
  }.freeze


  # Instantiate parsing environment.
  def initialize(receiver_ractor, *handler_args, **handler_kwargs)
    # `MIMEjr.initialize` sets up pretty much everything for us
    super(receiver_ractor, *handler_args, **handler_kwargs)

    # …except we should override the output container with a `::Hash`.
    # `MIMEjr` just uses a flat `::Set` subclass, but `MrMIME` needs `{CYI => CYO}`.
    @out = ::Hash.new
  end

  # Scratch object to be filled and torn down repeatedly while parsing.
  def cyo; @out[@cyi] ||= ::CHECKING::YOU::OUT::new(@cyi); end

  # Does the given media-type `String` match any available needles?
  # Can be a `CYI` exact match, a `String` glob match, or a `Regexp` match of a type name,
  # e.g. `CYI[:possum, :image, :jpeg]`, `"*jpeg"`, and `/.*jpeg/` would all match `"image/jpeg"`.
  def awen?(media_type)
    @needles[::CHECKING::YOU::IN].map { _1.eql?(media_type) }.any? or
      @needles[::String].map { File.fnmatch?(_1, media_type) }.any? or
      @needles[::Regexp].map { _1 =~ media_type }.any?
  end

  # Callback for the start of any XML Element.
  def start_element(name)
    @parse_stack.push(name)
    return if self.element_skips.include?(name)

    # Since we no longer explicitly load all `<mime-type>`s we can avoid a lot of `ObjectSpace` churn
    # by skipping this Element iff no match was made, i.e. iff `@cyi` is `nil`.
    # Of course this means we can't skip `<mime-type>` itself because the match is made based on
    # the `type` attribute to that Element, handled in the `attr_value` method below.
    return unless @cyi or name == :"mime-type"
    case name
    when :"mime-type" then
      # Nullify any previous `<mime-type>`'s match when entering a new type Element.
      @cyi = nil
    when :match then
      # Mark any newly-added Sequence as eligible for a full match candidate.
      @i_can_haz_magic = true
      @speedy_cat.append(::CHECKING::YOU::OUT::SequenceCat.new)
    when :magic then
      # To avoid an extra allocation, re-use a previous `@speedy_cat` if it is left emptied.
      @speedy_cat = ::CHECKING::YOU::OUT::SpeedyCat.new if @speedy_cat.nil?
    when :"magic-deleteall" then self.cyo.clear_content_fragments
    when :glob then
      @stick_around = ::CHECKING::YOU::OUT::StickAround.new
    when :"glob-deleteall" then self.cyo.clear_pathname_fragments
    when :treemagic then
      # TODO
    end
  end

  # Callback for element attributes a.k.a where most of the important data lives.
  def attr_value(attr_name, value)
    # `parse_stack` can be empty here in which case its `#last` will be `nil`.
    # This happens e.g. for the two attributes of the XML declaration '<?xml version="1.0" encoding="UTF-8"?>'.
    return if self.element_skips.include?(@parse_stack.last)

    # If `@cyi == nil` then we haven't matched the currently-parsing MIME type to one of our search needles.
    # We should allow `<mime-type>` parsing through regardless, because `<mime-type type="what/ever">`
    # is where the matching comes from :)
    return unless @cyi or @parse_stack.last == :"mime-type"

    # Avoid the `Array` allocation necessary when using pattern matching `case` syntax.
    # I'd still like to refactor this to avoid the redundant `attr_name` `case`s.
    # Maybe a `Hash` of `proc`s?
    case @parse_stack.last
    when :"mime-type" then @cyi = ::CHECKING::YOU::IN::from_ietf_media_type(value.as_s) if attr_name == :type and self.awen?(value.as_s)
    when :match then
      case attr_name
      when :type   then @speedy_cat.last.format = self.magic_eye[value.as_s]
      when :value  then @speedy_cat.last.cat = value.as_s
      when :offset then @speedy_cat.last.boundary = value.as_s
      when :mask   then @speedy_cat.last.mask = BASED_STRING.call(value.as_s)
      end
    when :magic          then @speedy_cat&.weight = value.as_i if attr_name == :priority
    when :alias          then self.cyo.add_aka(::CHECKING::YOU::IN::from_ietf_media_type(value.as_s)) if attr_name == :type
    when :"sub-class-of" then self.cyo.add_parent(::CHECKING::YOU::IN::from_ietf_media_type(value.as_s)) if attr_name == :type
    when :glob then
      case attr_name
      when :weight           then @stick_around.weight = value.as_i
      when :pattern          then @stick_around.replace(value.as_s)
      when :"case-sensitive" then @stick_around.case_sensitive = value.as_bool
      end
    when :"root-XML" then
      #case attr_name
      #when :namespaceURI then  # TODO
      #when :localName then  # TODO
      #end
    end
  end

  # Callback method for textual element contents, e.g. <hey>sup</hey>
  #                                          This part ------^
  def text(element_text)
    return if self.element_skips.include?(@parse_stack.last)
    return unless @cyi
    case @parse_stack.last
    when :comment            then self.cyo.description = element_text
    when :acronym            then self.cyo.acronym = element_text
    when :"expanded-acronym" then self.cyo.acronym = element_text
    end
  end

  # Callback for end-of-element events, i.e. the opposite of `start_element`.
  # Used to clean up scratch variables or save a successful match.
  def end_element(name)
    return if self.element_skips.include?(@parse_stack.last)
    raise Exception.new('Parse stack element mismatch') unless @parse_stack.pop == name
    return unless @cyi or name == :"mime-type"
    case name
    when :"mime-type" then
      @cyi = nil
    when :match then
      # The Sequence stack represents a complete match once we start popping Sequences from it,
      # which we can know because every `<match>` stack push sets `@i_can_haz_magic = true`.
      # If there is only a single sub-sequence we can just add that instead of the container.
      if @i_can_haz_magic then
        self.cyo.add_content_fragment(
          # Add single-sequences directly instead of adding their container.
          @speedy_cat.one? ?
            # Transfer any non-default `weight` from the container to that single-sequence.
            @speedy_cat.pop.tap { _1.weight = @speedy_cat.weight } :
            # Otherwise go ahead and add a copy of the container while also preparing the
            # local container for a possible next-branch to the `<magic>` tree.
            @speedy_cat.dup.tap { @speedy_cat.pop }
        )
      else
        # We should still get rid of the last content-match structure here even if we didn't save it.
        @speedy_cat.pop
      end
      # Mark any remaining partial Sequences as ineligible to be a full match candidate,
      # e.g. if we had a stack of [<match1/><match2/><match3/>] we would want to add a
      # candidate [m1, m2, m3] but not the partials [m1, m2] or [m1] as we clear out the stack.
      @i_can_haz_magic = false
    when :magic then
      # `SpeedyCat#clear` will unset any non-default `weight` so we can re-use it cleanly.
      @speedy_cat.clear
    when :glob then
      self.cyo.add_pathname_fragment(@stick_around) unless @stick_around.nil?
    end
  end

  # Trigger a search for all needles received by our `::Ractor` since the last `#search`.
  # See the overridden `self.new` for more details of our `::Ractor`'s message-handling loop.
  def do_the_thing(the_trigger_of_innocence)
    # Don't bother parsing anything if there's nothing for us to match.
    # `MIMEjr` will trigger us even if it didn't send us any needles first.
    self.parse_mime_packages unless @needles.values.map(&:nil?).all?

    # We can't send our built CYOs in on-the-fly because a single type's data can be spread out
    # over any number of our enabled `SharedMIMEinfo` XML package files.
    # The only way we can trust that we have it all is to wait and do them here all at once.
    @out.transform_values!(&Ractor.method(:make_shareable))
    @out.each_value { @receiver_ractor.send(_1, move: true) }
    @out.clear

    # Forward a trigger message back to the main message-loop to signify the completion of our parsing.
    @receiver_ractor.send(the_trigger_of_innocence, move: true)
    @needles.clear
  end
end

