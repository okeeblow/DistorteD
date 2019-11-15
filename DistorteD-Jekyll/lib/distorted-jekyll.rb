require 'invoker'

# Register DistorteD's entrypoint class with Liquid.
# `Invoker` will mix in the proper handler module for the given media.
Liquid::Template.register_tag('distorted', Jekyll::DistorteD::Invoker)
