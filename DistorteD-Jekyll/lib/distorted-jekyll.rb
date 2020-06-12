require 'distorted-jekyll/blocks'
require 'distorted-jekyll/injection_of_love'
require 'distorted-jekyll/invoker'

# I want to be able to use:
# - Array#dig and Hash#dig (Ruby 2.3) https://bugs.ruby-lang.org/issues/11643
# - Lonely operator (Ruby 2.3) https://bugs.ruby-lang.org/issues/11537
# - Hash#transform_keys (Ruby 2.5) https://bugs.ruby-lang.org/issues/13583
unless Hash.method_defined? :dig and Hash.method_defined? :transform_keys
  raise RuntimeError.new('Please use DistorteD with Ruby 2.5.0 or newer.')
end

# Register DistorteD's entrypoint class with Liquid.
# `Invoker` will mix in the proper handler module for the given media.
Liquid::Template.register_tag('distorted', Jekyll::DistorteD::Invoker)

# Register a block version for arranging multiple pieces of media.
Liquid::Template.register_tag('distort', Jekyll::DistorteD::BLOCKS)

# Transform Markdown image syntax ![alt](url.jpg "title")
# to instances of our liquid tag {% distorted %}
# Available hooks can be seen here:
#   https://github.com/jekyll/jekyll/blob/master/lib/jekyll/hooks.rb
# `:documents` does not seem to include `_pages` but does include `_posts`.
Jekyll::Hooks.register(:pages, :pre_render, &distort_markdown)
Jekyll::Hooks.register(:posts, :pre_render, &distort_markdown)
