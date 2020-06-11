require 'distorted-jekyll/blocks'
require 'distorted-jekyll/injection_of_love'
require 'distorted-jekyll/invoker'

raise 'DistorteD depends on some features introduced in Ruby 2.3' unless RUBY_VERSION.to_f > 2.3

# Register DistorteD's entrypoint class with Liquid.
# `Invoker` will mix in the proper handler module for the given media.
Liquid::Template.register_tag('distorted', Jekyll::DistorteD::Invoker)

# Register a block version for arranging multiple pieces of media.
Liquid::Template.register_tag('distort', Jekyll::BLOCKS)

# Transform Markdown image syntax ![alt](url.jpg "title")
# to instances of our liquid tag {% distorted %}
# Available hooks can be seen here:
#   https://github.com/jekyll/jekyll/blob/master/lib/jekyll/hooks.rb
# `:documents` does not seem to include `_pages` but does include `_posts`.
Jekyll::Hooks.register(:pages, :pre_render, &distort_markdown)
Jekyll::Hooks.register(:posts, :pre_render, &distort_markdown)
