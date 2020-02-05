require 'kramdown'

# Replace standard Markdown images to instances of DistorteD via its Liquid tag.
#
# Jekyll processes Liquid templates before processing page/post Markdown,
# so we can't rely on customizing the Markdown renderer's `:img` element
# output as a means to invoke DistorteD.
# https://jekyllrb.com/tutorials/orderofinterpretation/
#
# Prefer the POSIX-style bracket expressions (e.g. [[:digit:]]) over
# basic character classes (e.g. \d) because they match Unicode
# instead of just ASCII.
# https://ruby-doc.org/core/Regexp.html#class-Regexp-label-Character+Classes
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
MD_IMAGE_REGEX = %r&
  # Image container
  (
    # Preceding-line attribute list
    (
      # One blank line with newline via :space:
      ^$[[:space:]]
      # Any amount of blank space before AL
      [[:blank:]]*
      # IAL regex from Section 5.3:
      # https://golem.ph.utexas.edu/~distler/maruku/proposal.html
      (?<pre_al>\{:(\\\}|[^\}])*\})
      # Any amount of trailing whitespace followed by a newline.
      [[:blank:]]*[[:space:]]
    )?  # Match all of that, or nothing.
    # Eat list items containing images since that's the syntax
    # I decided to use for media block arrangements.
    (
      # Include both unordered (-+*) and ordered (\d\. like `1.`) lists.
      # Support any amount of leading whitespace and one space/tab
      # between list delimiter and the image.
      [[:blank:]]*[-\*\+|\d\.][[:blank:]]
      # Support an optional IAL for the list element as shown in Kramdown docs:
      # https://kramdown.gettalong.org/syntax.html#lists
      # Ctrl+F "{:.cls}"
      (\{:(\\\}|[^\}])*\})?
    )?  # List items are optional!
    # Match Markdown image syntax:
    #   ![alt text](/some/path/to/image.png 'title text'){:other="options"}
    !\[(?<alt>(\\\]|[^\]])*)\]
    # Match img src as anything after the '(' and before ')' or
    # anything that could be a title.
    # Assume titles will be quoted.
    \((?<src>[^'")]+)
    # Title is optional.
    # Don't including the opening or closing quotes in the capture.
    (['"](?<title>[^'"]*)['"])?
    # The closing ')' will always be present.
    \)
    # IALs may be on the same line as the image after some amount of whitespace.
    ([[:blank:]]*(?<inline_al>\{:(\\\}|[^\}])*\}))*
    # Also support optional IALs on the line following the image.
    # :space: matches newlines regardless of encoding.
    ([[:space:]][[:blank:]]*(?<post_al>\{:(\\\}|[^\}])*\})*)?
  )+  # Capture multiple images together for block display.
&x

def extract_list(hash, collect = false)
  hash.map do |k, v|
    v.is_a?(Array) ? extract_list(v, (k == :children)) : 
       (collect ? v : nil)
  end.compact.flatten
end

def get_images(hash, collection = nil)
  hash[:children]
end

def distort_markdown
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
      document.content = document.content.gsub(MD_IMAGE_REGEX) { |match| 
        Kramdown::Document.new(match).to_liquid
      }
    end
  }
end

module Kramdown

  module Converter

    # Converts a Kramdown::Document to a nested hash for further processing or debug output.
    class Liquid < Base
    end

  end
end
