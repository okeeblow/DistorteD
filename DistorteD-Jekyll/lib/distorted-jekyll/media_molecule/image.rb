require 'distorted-jekyll/molecule/C18H27NO3'
require 'distorted-jekyll/static/image'

module Jekyll
  module DistorteD
    module Molecule
      module Image

        # Spice up our singleton.
        include Jekyll::DistorteD::Molecule::C18H27NO3;

        # Reference these instead of reassigning them. Consistency is mandatory.
        MEDIA_TYPE = Cooltrainer::DistorteD::Image::MEDIA_TYPE
        MIME_TYPES = Cooltrainer::DistorteD::Image::MIME_TYPES

        ATTRS = Cooltrainer::DistorteD::Image::ATTRS
        ATTRS_DEFAULT = Cooltrainer::DistorteD::Image::ATTRS_DEFAULT
        ATTRS_VALUES = Cooltrainer::DistorteD::Image::ATTRS_VALUES

        CONFIG_SUBKEY = :image


        # https://developer.mozilla.org/en-US/docs/Web/HTML/Element/img#attr-loading
        def loading
          # These have been mixed in to the singleton class already for us to be able to get here.
          values = ATTRS_VALUES

          # The instance var is set in Invoker when the molecule is mixed in.
          if values[:loading].include?(@loading)
            @loading
          else
            values[:loading].to_s
          end
        end


        # This will become render_to_output_buffer(context, output) some day,
        # according to upstream Liquid tag.rb.
        def render(context)
          super
          begin
            parse_template.render({
              'name' => @name,
              'path' => @url,
              'alt' => @alt,
              'title' => @title,
              'href' => @href,
              'caption' => @caption,
              'loading' => loading,
              'filenames' => @filenames,
            })
          rescue Liquid::SyntaxError => l
            # TODO: Only in dev
            l.message
          end
        end

        def static_file(site, base, dir, name, url, dimensions, types, filenames)
          Jekyll::DistorteD::Static::Image.new(site, base, dir, name, url, dimensions, types, filenames)
        end

      end
    end
  end
end
