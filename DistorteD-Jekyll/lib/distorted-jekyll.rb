require 'blocks'
require 'injection_of_love'
require 'invoker'

# Register DistorteD's entrypoint class with Liquid.
# `Invoker` will mix in the proper handler module for the given media.
Liquid::Template.register_tag('distorted', Jekyll::DistorteD::Invoker)

# Register a block version for arranging multiple pieces of media.
Liquid::Template.register_tag('distort', Jekyll::BLOCKS)

# Transform Markdown image syntax ![alt](url.jpg "title")
# to instances of our liquid tag {% distorted %}
Jekyll::Hooks.register(:documents, :pre_render, &distort_markdown)
