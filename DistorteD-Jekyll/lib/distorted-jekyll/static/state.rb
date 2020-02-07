
module Jekyll
  # Tag-specific StaticFile child that handles thumbnail generation.
  class StaticState < Jekyll::StaticFile

    def initialize(
      site,
      base,
      dir,
      name,
      url,
      collection = nil
    )
      @tag_name = self.class.name.split('::').drop(1).join('::')
      Jekyll.logger.debug(@tag_name, "#{base}/#{dir}/#{name} -> #{url}")
      @base = base
      @dir = dir
      @name = name
      @url = url
      # Constructor args for Jekyll::StaticFile:
      # site - The Jekyll Site object
      # base - The String path to the generated `_site` directory.
      # dir  - The String path for generated images, aka the page URL.
      # name - The String filename for one generated or original image.
      super(
        site,
        base,
        dir,
        name
      )
    end

    # site_dest: string realpath to `_site_` directory
    def destination(dest, suffix = nil)
      File.join(dest, @url, DistorteD::Floor::image_name(@name, suffix))
    end

    def modified?
      return true
    end

    def orig_path
      File.join(@base, @dir, @name)
    end
  end
end
