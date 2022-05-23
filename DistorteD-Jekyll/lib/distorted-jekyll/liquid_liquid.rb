require 'liquid/drop'
require 'liquid/template'

begin
  require 'liquid/c'  # Gotta go fast
rescue LoadError
  # This is an optional dependency: https://github.com/Shopify/liquid-c
end

require 'distorted-floor/checking_you_out'
using ::DistorteD::CHECKING::YOU::OUT


module Cooltrainer

  # DistorteD Liquid::Template-caching Hash.
  # Jekyll has its own Liquid cache enabled by default as of 4.0,
  # but the Jekyll::LiquidRenderer::File has a different interface
  # than Liquid::Template (e.g. no :assigns accessor).
  @@watering rescue begin
    @@watering = Hash[]
  end


  # Entry-point for MediaMolecules to render HTML (and maybe eventually other formats!).
  #
  # Liquid is arguably a poor choice for this use case since it is designed
  # to handle arbitrary user-supplied templates in a safe way,
  # versus e.g. ERB which allows in-template execution of arbitrary Ruby code,
  # but our templates are bundled here in the Gem (ostensibly) should be trustworthy.
  #
  # I considered using Nokogiri's DocumentFragment Builder instead:
  # fragment = Nokogiri::HTML::DocumentFragment.parse(''.freeze)
  # Nokogiri::HTML::Builder.with(fragment) do |doc|
  #   doc.picture {
  #     changes.each { |change| doc.source(:srcset=change.name) }
  #   }
  # end
  # fragment.to_html
  #
  # But the way DistorteD works (with `::CHECKING::YOU::OUT#distorted_template_method`)
  # means we would need a way to collate child elements anyway, since each call
  # to a :distorted_template_method should generate only one variation,
  # meaning we'd end up with a bunch of <source> tag Strings but would
  # still need to collect them under a parent <picture> with a sibling <img>.
  #
  # Liquid is already heavily used by Jekyll, and of course DistorteD-Jekyll
  # itself is a Liquid::Tag, so we may as well use it.
  # Nokogiri, on the other hand, is not an explicit dependency of Jekyll.
  # It will most likely be available, and DD itself pulls it in via SVGO
  # and others, but Liquid will also allow us the flexibility to render
  # formats other than just HTML/XML, e.g. BBCode or even Markdown.
  #
  # I might revisit this design decision once I experience working with more
  # media formats and in more page contexts :)
  ElementalCreation = Struct.new(:element, :name, :parent, :children, :template, :assigns, :change, keyword_init: true) do

    def initialize(element, change = nil, parent: nil, children: Array.new, template: nil, assigns: Hash[])
      super(
        # Symbol Template name, corresponding to a Liquid template file name,
        # not necessarily corresponding to the exact name of the element we return.
        element: element,
        change: change,
        name: change&.name || element,  # TODO: Use change tag here as well
        # Symbol name or Enumerable[Symbol] names of parent Element(s) we should be under,
        # in order from outermost to innermost nesting.
        # This is used to collate Change templates under a required parent Element,
        # e.g. <source> tags must be under a <picture> or a <video> tag.
        parent: parent,
        # Flat Array of child (and grandchild and etc) ElementalCreation Structs
        # that will be sorted into a tree by our #render method.
        children: children,
        # Our associated Liquid::Template, based on our element name.
        template: template || self.WATERING(element),
        # Container of variables we want to render in Liquid besides what's covered by the basics.
        assigns: assigns,
      )

      # Go ahead and define accessors for any assigns we already know about.
      # Others are supported via the :method_missing below.
      assigns.each_key { |assign|
        define_method(assign) do; self[:assigns].fetch(assign, nil); end
        define_method("#{assign.to_s}=") do |value|; self[:assigns].store(assign, value); end
      }
    end

    # Hash[String] => Integer containing weights for ::CHECKING::YOU::OUT sorting.
    # Weights are assigned in auto-incrementing Array order and will be called from :<=>.
    # Sub-types near the beginning will sort before sub-types near the bottom.
    # This is important for things like <picture> tags where the first supported <source> child
    # encountered is the one that will be used, so we want vector types (SVG) to come first,
    # then modern annoying formats like AVIF/WebP, then old standby types like PNG.
    # TODO: Sort things other than Images
    SORT_WEIGHTS = [
      :svg,
      :avif,
      :webp,
      :png,
      :jpeg,
      :gif,
    ].map.with_index.to_h
    # Return a static 0 weight for unknown types.
    SORT_WEIGHTS.default_proc = Proc.new { 0 }

    # Elements should sort themselves under their parent when rendering.
    # Use predefined weights, e.g.:
    #   irb> SORT_WEIGHTS['avif']
    #   => 1
    #   irb> SORT_WEIGHTS['png']
    #   => 3
    #   irb> SORT_WEIGHTS['avif'] <=> SORT_WEIGHTS['png']
    #   => -1
    def <=>(otra)
      SORT_WEIGHTS[self.change&.type&.genus] <=> SORT_WEIGHTS[otra&.change&.type&.genus]
    end

    # Generic Liquid template loader
    # Jekyll's site-wide Liquid renderer caches in 4.0+ and is usable via
    # `site.liquid_renderer.file(cache_key).parse(liquid_string)`,
    # but the Jekyll::LiquidRenderer::File you get back doesn't let us
    # play with the `assigns` directly, so I stopped using the site renderer
    # in favor of our own cache.
    def WATERING(template_filename)
      begin
        # Memoize parsed Templates to this Struct subclass.
        @@watering[template_filename] ||= begin
          template = File.join(__dir__, 'liquid_liquid'.freeze, "#{template_filename}.liquid".freeze)
          Jekyll.logger.debug('DistorteD::WATERING', template)
          Liquid::Template.parse(File.read(template))
        end
      rescue Liquid::SyntaxError => l
        # This shouldn't ever happen unless a new version of Liquid
        # breaks syntax compatibility with our templates somehow.
        l.message
      end
    end  #WATERING 

    # Returns the rendered String contents of this and all child Elements.
    def render
      # Sort our flat Array of child Elements into three groups based on the parent Element
      # they want to attach to.
      # Do we already have another matching Element, do we need to create the parent,
      # or is no parent wanted, in which case it will be our direct child?
      has_matching_parent, missing_parent, no_parent_needed = self[:children].map { |child|
        # Support duplicate-Change `:children` defined as Array[Symbol].
        child.is_a?(Symbol) ? self.class.new(child, self[:change], assigns: self[:assigns]) : child
      }.partition { |child|
        # Separate the Elements that will be our direct children out from all the others.
        #
        # It's important to check for parent==our_element as well as just nil,
        # to avoid an infinite loop if we fail to nullify the child's parent
        # where each level will create another duplicate parent.
        child.parent.nil? or child.parent == self[:element]
      }.yield_self { |(no_parent_needed, wants_parent)|
        # Further separate the Elements that are not our direct children
        # based on whether or not we need to create their parent Element.
        wants_parent.partition { |child|
          # Does the original flat Array of children include an Element
          # matching the desired parent?
          self[:children]&.group_by(&:element).keys.include?(child.parent)
       }.push(no_parent_needed)  # Append our direct child Array to the Array[Array] we get from #partition.
      }

      # Set up a Hash[Symbol] => Element to hold the elements that will be rendered as our direct children,
      # grouped so we can find and attach other Elements to them as their children.
      direct_children = no_parent_needed.group_by(&:element)
      # "Missing parent" Elements can be given all at once to a new intermediate parent Element,
      # then *that* Element will become our direct child.
      missing_parent.group_by(&:parent).each_pair { |parent, children|
        # Give the new parent a copy of our Change to allow it to fill out
        # contextual variables if desired, e.g. including the :alt attribute in a generated <img>.
        direct_children.store(parent, Array[self.class.new(parent, self[:change], children: children, assigns: self[:assigns])])
      }
      # "Matched parent" Elements will already have a suitable detected parent Element
      # in the :direct_children Hash.
      has_matching_parent.group_by(&:parent).each_pair { |parent, children|
        # NOTE: This currently only appends the matched children to the last (usually only)
        # matching parent Element. I don't yet have a use-case to add anything more advanced.
        (direct_children[parent].nil? ?
          (direct_children.empty?     ?
            self.children : direct_children.values.last.last.children
          ) :
          direct_children[parent].last.children
        ).concat(children)
      }

      # Now we're ready to render! Our template will need to interate any child Elements in Liquid.
      self[:template].render(
        self[:assigns].merge(Hash[
          # Most Elements will be associated with a Change Struct
          # encapsulating a single wanted variation on the source file.
          :change => self[:change].nil? ? nil : Cooltrainer::ChangeDrop.new(self[:change]),
          # Take the Hash of our direct child Elements and recursively render them
          # into our template's String output.
          # The :sort will use ElementalCreation's :<=> method.
          :children => direct_children.values.flatten.sort.map(&:render),
        ]).transform_keys(&:to_s).transform_values { |value|
          # Liquid wants String keys and values, not Symbols.
          value.is_a?(Symbol) ? value.to_s : value
        }
      )
    end

    # Calling :flatten on an Array[self] will fail unless we override :to_ary to stop
    # implicitly looking like an Array. Or we could implement :flatten, but this probably
    # fixes other situations too.
    # https://tenderlovemaking.com/2011/06/28/til-its-ok-to-return-nil-from-to_ary.html
    def to_ary; nil; end
    def to_a;   nil; end

    # Expose Liquid's 'assigns' accessors for any keys we weren't given upfront.
    def method_missing(meth, *a)
      # Grab the key from the method name, minus the trailing '=' for writers.
      meth.to_s.end_with?('='.freeze) ? self[:assigns].store(meth.to_s.chomp('='.freeze).to_sym, a.first) : self[:assigns].fetch(meth, nil)
    end

    # Destination filename, or the element name.
    def to_s; (self[:name] || self[:element]).to_s; end

    # e.g. <ElementalCreation::source name=IIDX-turntable-full.svg, parents=[:anchor, :picture]>
    def inspect; "<#{self.class.name.split('::'.freeze).last}::#{self[:element]}#{
      [:name, :children].map { |k| (self[k].nil? || self[k]&.empty?) ? nil : " #{k.to_s}=#{self[k]}" }.compact.join(','.freeze)
    }>"; end

  end  # Struct ElementalCreation


  # Wrap a Change in a Drop that emits Element attribute keys as well as the value.
  # An underlying ChangeDrop will instantiate us as an instance variable
  # and forward its Change to us, then return that instance from its own :attr method.
  #
  # Our templates can use this to avoid emitting empty attributes
  # for corresponding empty values by calling {{ change.attr.whatever }}
  # instead of invoking the regular ChangeDrop via {{ change.whatever }}.
  #
  # For example, if a <source>'s Change defines a media-query,
  # {{ change.media }} will emit the plain value (e.g. `min-width: 800px`)
  # and would typically be used in a template inside an explicit attribute key,
  # e.g. `<source … media="{{ change.media }}"\>`.
  #
  # A template could instead call this drop via e.g. <source … {{ attr_media }}\>`
  # to emit the same thing if a media-query is set but emit nothing if one isn't!
  class ChangeAttrDrop < Liquid::Drop
    def initialize(change)
      @change = change
    end
    def liquid_method_missing(method)
      # The underlying ChangeDrop is what responds to :attr, so we only
      # need to respond to the Change keys in the same way ChangeDrop does.
      value = @change&.send(method.to_sym)
      # Return an empty String if there is no value, otherwise return `attr="value"`.
      # Intentional leading-space in output so Liquid tags can abut in templates.
      value.nil? ? ''.freeze : " #{method.to_str}=\"#{value.to_s}\""
    end
  end  # Struct ChangeAttrDrop


  # Wrap a Change in a Drop that our Element Liquid::Templates can use
  # to emit either values-alone or keys-and-values for any attribute
  # of any one variation ot a media file.
  class ChangeDrop < Liquid::Drop
    def initialize(change)
      @change = change
    end
    def initialism
      @initialism ||= @change.type&.genus&.to_s.split(::CHECKING::YOU::OUT::type_separators)[0].upcase
    end
    def attr
      # Use a ChangeAttrDrop to avoid emitting keys for empty values.
      # It will respond to its own Change-key method just like we do.
      @attr ||= Cooltrainer::ChangeAttrDrop.new(@change)
    end
    def liquid_method_missing(method)
      # Liquid will send us String keys only, so translate them
      # to Symbols when looking up in the Change Struct.
      # Don't explicitly call :to_s before returning,
      # because we might be returning an Array.
      @change&.send(method.to_sym) || super
    end
  end  # Struct ChangeDrop

end
