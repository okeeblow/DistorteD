
module Jekyll
  module DistorteD
    module Static
      class State < Jekyll::StaticFile

        def initialize(
          site,
          base,
          dir,
          name,
          url,
          collection = nil
        )
          @tag_name = self.class.name.split('::').drop(1).join('::').to_sym.freeze
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

        def basename
          File.basename(@name, '.*')
        end

        def extname
          File.extname(@name)
        end

        # site_dest: string realpath to `_site_` directory
        def destination(dest, tag = nil, extension = nil)
          File.join(dest, @url, filename(basename, tag, extension))
        end

        def modified?
          return true
        end

        def src_path
          File.join(@base, @dir, @name)
        end

      end  # state
    end  # Static
  end  # DistorteD
end  # Jekyll
