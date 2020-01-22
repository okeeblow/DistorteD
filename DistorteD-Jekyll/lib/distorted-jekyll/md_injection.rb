require 'kramdown'

# Replace standard Markdown images to instances of DistorteD via its Liquid tag.
#
# Jekyll processes Liquid templates before processing page/post Markdown,
# so we can't rely on customizing the Markdown renderer's `:img` element
# output as a means to invoke DistorteD.
# https://jekyllrb.com/tutorials/orderofinterpretation/

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
      # ![alt text](filename.png 'Title text'){:other="options"}
      # or
      # ![Eh](hello.jpg 'Receiver')
      # {:ial="is on a new line!"}
      document.content = document.content.gsub(
        # Thank you for being here to share my pain.
        /((^$\n[[:blank:]]*(?<pre_al>{:[^}]+})\n[[:blank:]]*)?([[:blank:]]*[-*+|\d\.][[:blank:]])?!\[(?<alt>.*)\]\((?<name>[^'")]+)(['"](?<title>[^'")]+)['"])?\)(?<inline_al>{:([^}]+)})*(\n[[:blank:]]*(?<post_al>{:([^}]+)})*)?)+/,
      ) { |match| Kramdown::Document.new(match).to_hash_ast }
    end
  }
end
