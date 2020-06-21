
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

        # Returns the to-be-written path of a single standard StaticFile.
        # The value returned by this method is only the 'main' or 'original'
        # (even if modified somehow) file and does not include the
        # path/filenames of any variations.
        # This method will be called by jekyll/lib/cleaner#new_files
        # to generate the list of files that need to be build or rebuilt
        # for a site. For this reason, this method shouldn't do any kind
        # of checking the real filesystem, since e.g. its URL-based
        # destdir might not exist yet if the Site.dest is completely blank.
        def destination(dest)
          File.join(dest, @dd_dest, @name)
        end

        # Return the absolute path to the top-level destination directory
        # of the currently-working media. This will usually be the same path
        # as the Jekyll post/page's generated HTML output.
        def dd_dest(dest)
          File.join(dest, @dd_dest)
        end

        # This method will be called by our monkey-patched Jekyll::Cleaner#new_files
        # in place of the single-destination method usually used.
        # This allows us to tell Jekyll about more than a single file
        # that should be kept when regenerating the site.
        # This makes DistorteD fast!
        def destinations(dest)
          # TODO: Make outputting the original file optional. Will need to change
          # templates, `modified?`s, and `generate`s to do that.
          @filenames.map{|f| File.join(dd_dest(dest), f)} << destination(dest)
        end

      end  # state
    end  # Static
  end  # DistorteD
end  # Jekyll
