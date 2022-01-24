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

  # Our parser will raise this custom `Exception` subclass when one of the loaded types necessitates
  # a re-parsing of the enabled package files. This can occur when:
  # - We are loading a type by an aliased name. After matching an `<alias>` tag we must start over
  #   to load any data defined under the canonical / non-aliased type that we missed on the first pass.
  # - We are loading a sub-type and need to go back for its parent(s) after matching a `<sub-class-of>`.
  OneMoreLovely = ::Class::new(::RuntimeError)

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
    when :magic then
      # To avoid an extra allocation, re-use a previous `@cat_sequence` if it is left emptied.
      @cat_sequence = ::CHECKING::YOU::OUT::SpeedyCat.new if @cat_sequence.nil?
    when :match then
      # Any time we add a new level of `<match>` to the `<magic>` stack,
      # the next `end_element(match)` will check the entire stack against our `@needles`.
      @i_can_haz_filemagic = true
      @cat_sequence.append(::CHECKING::YOU::OUT::SequenceCat.new)
    when :"magic-deleteall" then self.cyo.clear_content_fragments
    when :glob then
      @astraia = ::CHECKING::YOU::OUT::ASTRAIAの双皿.new if @astraia.nil?
    when :"glob-deleteall" then self.cyo.clear_pathname_fragments
    when :treemagic then @mother_tree = ::CHECKING::YOU::OUT::SpeedyCat.new if @mother_tree.nil?
    when :treematch then
      # Any time we add a new level of `<treematch>` to the `<treemagic>` stack,
      # the next `end_element(treematch)` will check the entire stack against our `@needles`.
      @i_can_haz_treemagic = true
      @mother_tree.append(::CHECKING::YOU::OUT::CosmicCat.new)
    when :"root-XML" then @re_roots = ::CHECKING::YOU::OUT::SweetSweet♥Magic::ReRoots::new if @re_roots.nil?
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
    case @parse_stack.last
    when :"mime-type"    then
      ::CHECKING::YOU::IN::from_iana_media_type(
        value.as_s,
        envelope: ::CHECKING::YOU::OUT::EverlastingMessage
      ).tap {
        (@cyi, fresh_cyo) = _1.shift
        # Don't replace/update types we've already partially loaded.
        @out.store(@cyi, fresh_cyo) unless @out.include?(@cyi)
      } if attr_name == :type and self.awen?(value.as_s)
    when :magic          then @cat_sequence&.weight = value.as_i if attr_name == :priority
    when :match          then
      case attr_name
      when :type         then @cat_sequence.last.format   = MAGIC_EYE[value.as_sym]
      when :value        then @cat_sequence.last.sequence = value.as_s
      when :offset       then @cat_sequence.last.boundary = value.as_s
      when :mask         then @cat_sequence.last.mask     = value.as_s
      end
    when :treemagic      then
      # Content-match byte-sequence container Element can specify a weight 0–100.
      @mother_tree&.weight = value.as_i if attr_name == :priority
    when :treematch      then
      # Rename the most common keys to avoid confusion with other 'type's and 'path's in CYO-land.
      case attr_name
      when :path         then @mother_tree.last.here_we_are    = ::Pathname::new(value.as_s)
      when :type         then @mother_tree.last.your_body      = value.as_s
      when :"match-case" then @mother_tree.last.case_sensitive = value.as_bool
      when :executable   then @mother_tree.last.executable     = value.as_bool
      when :"non-empty"  then @mother_tree.last.non_empty      = value.as_bool
      when :mimetype     then @mother_tree.last.inner_spirit   = value.as_s
      end
    when :alias          then self.cyo.add_aka(::CHECKING::YOU::IN::from_iana_media_type(value.as_s)) if attr_name == :type
    when :"sub-class-of" then self.cyo.add_parent(::CHECKING::YOU::IN::from_iana_media_type(value.as_s)) if attr_name == :type
    when :glob           then
      case attr_name
      when :weight           then @astraia.weight = value.as_i
      when :pattern          then @astraia.replace(value.as_s)
      when :"case-sensitive" then @astraia.case_sensitive = value.as_bool
      end
    when :"root-XML" then
      case attr_name
      when :namespaceURI then @re_roots.namespace = value.as_s
      when :localName    then @re_roots.localname = value.as_s
      end
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
    when :"mime-type" then @cyi = nil
    when :magic then
      # `SpeedyCat#clear` will unset any non-default `weight` so we can re-use it cleanly.
      @cat_sequence.clear
    when :match then
      # The `<magic>` stack represents a complete match only the first time we encounter end_element(match)
      # after pushing a `<match>` to the `<magic>` stack and setting `@i_can_haz_filemagic = true`.
      # If there is only a single sub-sequence we can just add that instead of the container.
      if @i_can_haz_filemagic then
        self.cyo.add_content_fragment(
          # Add single-sequences directly instead of adding their container.
          @cat_sequence.one? ?
            # Transfer any non-default `weight` from the container to that single-sequence.
            @cat_sequence.pop.tap { _1.weight = @cat_sequence.weight } :
            # Otherwise go ahead and add a copy of the container while also preparing the
            # local container for a possible next-branch to the `<magic>` tree.
            @cat_sequence.dup.tap { @cat_sequence.pop }
        )
      else
        # We should still get rid of the last content-match structure here even if we didn't save it.
        @cat_sequence.pop
      end
      # Mark any remaining partial Sequences as ineligible to be a full match candidate,
      # e.g. if we had a stack of [<match1/><match2/><match3/>] we would want to add a
      # candidate [m1, m2, m3] but not the partials [m1, m2] or [m1] as we clear out the stack.
      @i_can_haz_filemagic = false
    when :treemagic then @mother_tree.clear
    when :treematch then
      # The `<treemagic>` stack represents a complete match only the first time we encounter end_element(treematch)
      # after pushing a `<treematch>` to the `<treemagic>` stack and setting `@i_can_haz_treemagic = true`.
      if @i_can_haz_treemagic then
        self.cyo.add_tree_branch(
          @mother_tree.one? ?
            @mother_tree.pop.tap { _1.weight = @mother_tree.weight } :
            @mother_tree.dup.tap { @mother_tree.pop }
        )
      else
        # We should still get rid of the last tree-match structure here even if we didn't save it.
        @mother_tree.pop
      end
      @i_can_haz_treemagic = false
    when :glob then
      self.cyo.add_pathname_fragment(@astraia.sinistar) unless @astraia.nil?
      @astraia.clear
    when :"root-XML" then
      self.cyo.add_xml_root(@re_roots.dup) unless @re_roots.nil? or @re_roots&.empty?
      @re_roots.clear unless @re_roots.nil? or @re_roots&.empty?
    end
  end

  # Trigger a search for all needles received by our `::Ractor` since the last `#search`.
  # See the overridden `self.new` for more details of our `::Ractor`'s message-handling loop.
  def do_the_thing(the_trigger_of_innocence)
    # Use the value of our `EverlastingMessage` as a needle.
    self.awen(the_trigger_of_innocence.in_motion)
    begin
      # Don't bother parsing anything if there's nothing for us to match.
      # `MIMEjr` will trigger us even if it didn't send us any needles first.
      self.parse_mime_packages unless @needles.values.map(&:nil?).all?

      # Collect any parent types which must also be loaded, minus those in the "always-active" set.
      one_more_lovely = @out.values.map(&:parents).each_with_object(::Array::new) { |rents, oml|
        oml.push(*rents)
      }.compact.difference(
        ::CHECKING::YOU::OUT::GHOST_REVIVAL::STILL_IN_MY_HEART
      ).difference(@out.keys)

      # We can't send our built CYOs in on-the-fly because a single type's data can be spread out
      # over any number of our enabled `SharedMIMEinfo` XML package files.
      # The only way we can trust that we have it all is to wait and do them here all at once.
      @out.transform_values!(&Ractor.method(:make_shareable))
      while not @out.empty?
        @receiver_ractor.send(@out.shift, move: true)
      end

      # `@out` should already be empty here from the `while #shift` loop, but `#clear` it anyway :)
      @out.clear
      @needles.clear

      # Re-run the parser iff there are more types we must load.
      raise(OneMoreLovely) unless one_more_lovely.empty?
    rescue OneMoreLovely
      # Convert OMLs to regular needles.
      while not one_more_lovely.empty?
        self.awen(one_more_lovely.pop)
      end
      retry  # Re-parse with the new needles.
    end  # begin

    # Forward a trigger message back to the main message-loop to signify the completion of our parsing.
    @receiver_ractor.send(the_trigger_of_innocence, move: true)
  end
end

