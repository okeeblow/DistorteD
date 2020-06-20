
module Jekyll
  module DistorteD
    module Static
      class State < Jekyll::StaticFile

        def initialize(
          site,
          base,
          dir,
          name,
          dd_dest,
          url,
          dimensions,
          types,
          files,
          collection = nil
        )
          @tag_name = self.class.name.split('::').drop(1).join('::').to_sym.freeze

          # Path to Jekyll site root
          @base = base

          # Container dir of original file
          @dir = dir

          # Filename of original file
          @name = name

          # Destination URL for the post/page on which the media appears.
          @dd_dest = dd_dest
          @url = url

          # Config struct data down
          @dimensions = dimensions
          @types = types

          # Pre-generated list of desired filenames.
          # I would prefer to generate this here in StaticFile land,
          # but Liquid needs them too for the templates.
          @files = files
          @filenames = files.map{|f| f[:name]}.to_set

          # Hello yes
          Jekyll.logger.debug(@tag_name, "#{base}/#{dir}/#{name} -> #{url}})")

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

        # Return the absolute path to the top-level destination directory
        # of the currently-working media. This will usually be the same path
        # as the Jekyll post/page's generated HTML output.
        def dd_dest(dest)
          File.join(dest, @dd_dest)
        end
        end

      end  # state
    end  # Static
  end  # DistorteD
end  # Jekyll
