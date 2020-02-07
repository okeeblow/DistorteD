require 'distorted/floor'
require 'formats/video'

module Jekyll::DistorteD::Video

  MEDIA_TYPE = 'video'
  ATTRS = Set[:caption]

  # This will become render_to_output_buffer(context, output) some day,
  # according to upstream Liquid tag.rb.
  def render(context)
    super
    begin
      parse_template(context.registers[:site]).render({
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
    Jekyll::DistorteD::VideoFile.new(site, base, dir, name, url)
  end

end
