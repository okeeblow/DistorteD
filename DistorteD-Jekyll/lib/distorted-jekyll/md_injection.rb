require 'kramdown'

# Replace standard Markdown image syntax with instances of DistorteD
# via its Liquid tag.
#
#
### SYNTAX
#
# I'm calling individual media elements "images" here because I'm overloading
# the Markdown image syntax to express them. There is no dedicated
# syntax for other media types in any flavor of Markdown as of 2019,
# so that seemed like the cleanest and sanest way to deal
# with non-images in DistorteD.
#
# DistorteD::Invoker will do the media type inspection and handling
# once we get into Liquid Land. This is the approach suggested by
# CommonMark: https://talk.commonmark.org/t/embedded-audio-and-video/441/15
#
# Media elements will display as a visibly related group when
# two or more Markdown image tags exist in consecutive Markdown
# unordered (e.g. *-+) list item or ordered (e.g. 1.) list item lines.
# Their captions should be hidden until opened in a lightbox or as a tooltip
# on desktop browsers via ::hover state.
#
# The inspiration for this display can be seen in the handling
# of two, three, or four images in any single post on Tw*tter.
# DistorteD expands on the concept by supporting things such as groups
# of more than four media elements and elements of heterogeneous media types.
#
# Standalone image elements (not contained in list item) should be displayed
# as single solo elements spanning the entire usable width of the
# container element, whatever that happens to be at the point where
# our regex excised a block of Markdown for us to work with.
#
#
### TECHNICAL CONSIDERATIONS
#
# Jekyll processes Liquid templates before processing page/post Markdown,
# so we can't rely on customizing the Markdown renderer's `:img` element
# output as a means to invoke DistorteD.
# https://jekyllrb.com/tutorials/orderofinterpretation/
#
# Prefer the POSIX-style bracket expressions (e.g. [[:digit:]]) over
# basic character classes (e.g. \d) in regex because they match Unicode
# instead of just ASCII.
# https://ruby-doc.org/core/Regexp.html#class-Regexp-label-Character+Classes
#
#
### INLINE ATTRIBUTE LISTS
#
# Support additional arguments passed to DistorteD via Kramdown-style
# inline attribute lists.
# https://kramdown.gettalong.org/syntax.html#images
# https://kramdown.gettalong.org/syntax.html#inline-attribute-lists
#
# IALs can be on the same line or on a line before or after their
# associated flow element.
# In ambiguous situations (flow elements both before and after an IAL),
# the IAL applies to the flow element before it.
# All associated elements and IALs must be on contiguous lines.
#
# This page provides a regex for parsing IALs, Section 5.3:
# https://golem.ph.utexas.edu/~distler/maruku/proposal.html
#
#
### SOLUTION
#
# A `pre_render` hook uses this regex to process Markdown source files
# and replace instances of the Markdown image syntax with instances of
# DistorteD's Liquid tags.
# Single images will be replaced with {% distorted %}.
# Multiple list-item images will be replaced with a {% distort %} block.
#
# By doing with with a regex (sorry!!) I hope to avoid a hard dependency on
# any one particular Markdown engine. Though I only support Kramdown for now,
# any engine that supports IALs should be fine.
#
# High-level explanation of what we intend to match:
#
# {:optional_ial => line_before_image}  # Iff preceded by a blank line!
# (optional_list_item)? ![alt](image){:optional_ial => same_line}
# {:optional_ial => next_consecutive_line}
# Repeat both preceding matches (together) any number of times to parse
# a {% distort %} block.
# See inline comments below for more detail.
MD_IMAGE_REGEX = %r&
  # Matching group of a single image tag.
  (
    # Optional preceding-line attribute list.
    (
      # One blank line, because:
      # "If a block IAL is directly after and before a block-level element,
      #  it is applied to preceding element."  —Kramdown BAL docs
      #
      # /\R/ - A linebreak: \n, \v, \f, \r \u0085 (NEXT LINE),
      #   \u2028 (LINE SEPARATOR), \u2029 (PARAGRAPH SEPARATOR) or \r\n.
      ^$\R
      # Any amount of blank space on the line before block IAL
      ^[[:blank:]]*
      # IAL regex from Section 5.3:
      # https://golem.ph.utexas.edu/~distler/maruku/proposal.html
      (?<block_ial_before>\{:(\\\}|[^\}])*\})
      # Any amount of trailing whitespace followed by a newline.
      [[:blank:]]*$\R
    )?  # Match all of that, or nothing.
    # Begin matching the line that contains an image.
    ^
    # Match anything that might be between that start-of-line
    # and the first character (!) of an image.
    (
      # From Gruber's original Markdown page:
      # "List markers typically start at the left margin, but may be indented
      # by up to three spaces."
      # Include both unordered (-+*) and ordered (\d\. like `1.`) lists.
      (?<li>[ ]{0,3}[-\*\+|\d\.]
      # Support an optional IAL for the list element as shown in Kramdown docs:
      # https://kramdown.gettalong.org/syntax.html#lists
      # Ctrl+F "{:.cls}"
      (?<li_ial>\{:(\\\}|[^\}])*\})?
      # "List markers must be followed by one or more spaces or a tab."
      # https://daringfireball.net/projects/markdown/syntax#list
      ([ ]+|\t))
    )?  # Although any preceding elements are optional!
    # Match Markdown image syntax:
    #   ![alt text](/some/path/to/image.png 'title text'){:other="options"}
    #   beginning with the alt tag:
    !\[(?<alt>(\\[[:print:]]|[^\]])*)\]
    # Continuing with img src as anything after the '(' and before ')' or
    # before anything that could be a title.
    # Assume titles will be quoted.
    \((?<src>(\\[[:print:]]|[^'")]+))
    # Title is optional.
    # Ignore double-quotes in single-quoted titles and single-quotes
    # in double-quoted titles otherwise we can't use contractions.
    # Don't include the title's opening or closing quotes in the capture.
    ('(?<title>(\\[[:print:]]|[^']*))'|"(?<title>(\\[[:print:]]|[^"]*))")?
    # The closing ')' will always be present, title or no.
    \)
    # Optional IAL on the same line as the :img element **with no space between them**:
    # "A span IAL (or two or more span IALs) has to be put directly after
    #  the span-level element to which it should be applied, no additional
    #  character is allowed between, otherwise it is ignored and only
    #  removed from the output."  —Kramdown IAL docs
    (?<span_ial>\{:(\\\}|[^\}])*\})*[[:print:]]*$\R
    # Also support optional BALs on the lines following the image.
    (^[[:blank:]]*(?<block_ial_after>\{:(\\\}|[^\}])*\})+$\R)*
  )+  # Capture multiple images together for block display.
&x


def md_injection
  Proc.new { |document, payload|
    # Compare any given document's file extension to the list of enabled
    # Markdown file extensions in Jekyll's config.
    if payload['site']['markdown_ext'].include? document.extname.downcase[1..-1]
      # Convert Markdown images to {% distorted %} tags.
      #
      # Use the same Markdown parser as Jekyll to avoid parsing inconsistencies
      # between this pre_render hook and the main Markdown render step.
      # This is still effectively a Markdown-parsing regex (and still
      # effectively a bad idea lol) but it's the cleanest way I can come up
      # with right now for separating DistorteD-destined Markdown from
      # the rest of any given page.
      # NOTE: Attribute List Definitions elsewhere in a Markdown document
      # will be lost when converting this way. I might end up just parsing
      # the entire document once with my own `to_liquid` converter, but I've been
      # avoiding that as it seems wasteful because Jekyll then renders the entire
      # Markdown document a second time immediately after our Liquid tag.
      # It's fast enough that I should stop trying to prematurely optimize this :)
      # TODO: Implement MD → DD love using only the #{CONFIGURED_MARKDOWN_ENGINE},
      # searching for :img elements inside :li elements to build BLOCKS.
      document.content = document.content.gsub(MD_IMAGE_REGEX) { |match| 
        Kramdown::Document.new(match).to_liquid
      }
    end
  }
end


# Kramdown implementation of Markdown AST -> Liquid converter.
# Renders Markdown element attributes as key=value, also under the assumption
# of using gem 'liquid-tag-parser': https://github.com/dmalan/liquid-tag-parser
module Kramdown
  module Converter
    class Liquid < Base

      # The incoming parsed Markdown tree will include many spurious elements,
      # like container paragraph elements and the list item elements when
      # parsing DD Grid style Markdown. Use this function to map a tree of
      # arbitrary elements to a flat list of elements of a single type.
      def children(el, type)
        matched = []

        if el.is_a? Enumerable
        # We might want to run this against an Array output from an
        # earlier invokation of this method.
          el.each {
            |item| matched.push(*children(item, type))
          }
        elsif el.type.equal? type
          # If we find the type we're looking for, stop and return it.
          # Let it bring its children along with it instead of recursing
          # into them. This will let us match container-only elements
          # such as <li> by type without considering the type of its children,
          # for situation where its children are really what we want.
          matched.push(el)
        else
          # Otherwise keep looking down the tree.
          unless el.children.empty?
            el.children.each {
              |child| matched.push(*children(child, type))
            }
          end
        end
        matched
      end

      def flatten_attributes(el, type = :img)
        matched = {}

        if el.is_a? Enumerable
          # Support an Array of elements...
          el.each {
            |child| matched.merge!(flatten_attributes(child, type))
          }
        else
          # ...or a tree of elements.
          if el.type.equal? type
            # Images won't have a `:value` — only `:attr`s — and the only
            # important things in their `:options` (e.g. IAL contents)
            # will be duplicated in `class` or some other `:attr` anyway.
            # Those things should be added here if this is ever used in a
            # more generic context than just parsing the image tags.
            matched.merge!(el.attr) unless el.attr.empty?
          end
          unless el.children.empty?
            # Keep looking even if this element was one we are looking for.
            el.children.each {
              |child| matched.merge!(flatten_attributes(child, type))
            }
          end
        end
        matched
      end

      # Geenerates a DistorteD Liquid tag String given a Hash of element attributes.
      # Examples:
      #   {% distorted rpg-ra11.nfo alt="HellMarch INTENSIFIES" title="C&C RA2:YR NoCD NFO" encoding="IBM437" crop="none" %}
      #   {% distorted DistorteD.png alt="DistorteD logo" title="This is so cool" crop="none" loading="lazy" %}
      # The :additional_defaults Hash contains attribute values to set
      # iff those attributes have no user-given value.
      def distorted(attributes, additional_defaults: {})
        "{% distorted #{additional_defaults.transform_keys{ |k|
          # We will end up with a Hash of String-keys and String-values,
          # so make sure override-defaults are String-keyed too.
          k.to_s
        }.merge(attributes).select{ |k, v|
          # Filter out empty values, e.g. from an unfilled title/alt field
          # in a Markdown image.
          not v.empty?
        }.map{ |k, v|
          k.to_s + '="'.freeze + v.to_s + '"'.freeze
        }.join(' '.freeze)} %}"
      end

      # Kramdown entry point
      def convert(el)
        # The parsed "images" may also be audio, video, or some other
        # media type. There is only one Markdown image tag, however.
        imgs = children(el, :img)

        # Enable conceptual-grouping (BLOCKS) mode if the count of list item
        # elements matches the count of image elements in our
        # chunk of Markdown. Technically I should check to make sure each
        # image is the child of one of those list items,
        # but this is way easier until I (hopefully never) find a parsing
        # corner-case where this doesn't hold up.
        lists = children(el, :li)
        list_imgs = lists.map{|li| children(li, :img)}.flatten

        case lists.count
        when 0..1
          # Render one (1) image/video/whatever. This behavior is the same
          # regardless if the image is in a single-item list or just by itself.
          distorted(
            flatten_attributes(imgs.first),
            additional_defaults: {:crop => 'none'.freeze},
          )
        else
          # Render a conceptual group (DD::BLOCKS)

          if imgs.count != list_imgs.count
            # Sanity check :img count vs :img-in-:li count.
            # We should support the corner case where the regex matches
            # multiple consecutive lines, but with mixed list item status,
            # e.g. a solo image abuts a conceptual group and gets globbed
            # into a single match.
            # For now, however:
            raise "MD->img regex returned an unequal number of listed and unlisted tags."
          end

          "{% distort -%}\n#{list_imgs.map{ |img|
            distorted(flatten_attributes(img))
          }.join("\n")}\n{% enddistort %}"
        end
      end

    end
  end
end
