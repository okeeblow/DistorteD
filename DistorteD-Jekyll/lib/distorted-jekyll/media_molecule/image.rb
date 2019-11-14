require 'pathname'
require 'distorted/floor'
require 'formats/image'

module Jekyll::DistorteD::Image

  ATTRS = [:alt, :caption, :href]

  # This will become render_to_output_buffer(context, output) some day,
  # according to upstream Liquid tag.rb.
  def render(context)
    super
    begin
      template = File.join(File.dirname(__FILE__), '..', 'templates', 'image.liquid')

      # Jekyll's Liquid renderer caches in 4.0+.
      # Make this a config option or get rid of it and always cache
      # once I have more experience with it.
      cache_templates = true
      if cache_templates
        # file(path) is the caching function, with path as the cache key.
        # The `template` here will be the full path, so no versions of this
        # gem should ever conflict. For example, right now during dev it's:
        # `/home/okeeblow/Works/DistorteD/lib/image.liquid`
        picture = context.registers[:site].liquid_renderer.file(template).parse(File.read(template))
      else
        picture = Liquid::Template.parse(File.read(template))
      end

      picture.render({
        'name' => @name,
        'path' => @url,
        'alt' => @alt,
        'title' => @title,
        'href' => @href,
        'caption' => @caption,
        'sources' => sources(context.registers[:site]),
      })
    rescue Liquid::SyntaxError => l
      # TODO: Only in dev
      l.message
    end
  end

  def sources(site)
    config(site, :image).map { |d| {
      'name' => name(d['tag']),
      'media' => d['media']
    }}
  end

  def static_file(site, base, dir, name, url)
    Jekyll::DistorteD::ImageFile.new(site, base, dir, name, url)
  end

end
