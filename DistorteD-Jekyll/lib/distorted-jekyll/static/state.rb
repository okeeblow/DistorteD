
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
          @url = url
          @dest = File.join(base, File.dirname(url))

          # Config struct data down
          @dimensions = dimensions
          @types = types

          # Pre-generated list of desired filenames.
          # I would prefer to generate this here in StaticFile land,
          # but Liquid needs them too for the templates.
          @files = files
          @filenames = files.map{|f| f[:name]}.to_set

          # Hello yes
          Jekyll.logger.debug(@tag_name, "#{base}/#{dir}/#{name} -> #{url} (#{@dest})")

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

        def filename(name, tag = nil, extension = nil)
          "#{name}#{if tag ; '-' << tag.to_s; else ''; end}.#{if extension; extension.to_s; else extname; end}"
        end

        def modified?
          if Dir.exist?(@dir)
            # TODO: Make this smarter. It's not enough that all the generated
            # filenames should exist. Try a few more ways to detect subtler
            # "changes to the source file since generation of variations?
            # - atime? (not all filesystems will support)
            if @filenames.subset?(Dir.entries(@dir).to_set)
              return false
            else
              return true
            end
          end
          return true
        end

        def src_path
          File.join(@base, @dir, @name)
        end

      end  # state
    end  # Static
  end  # DistorteD
end  # Jekyll
