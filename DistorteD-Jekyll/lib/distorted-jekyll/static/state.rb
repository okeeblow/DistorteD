require 'set'

module Jekyll
  module DistorteD
    module Static
      class State < Jekyll::StaticFile

        def initialize(
          site,
          base,
          dir,
          name,
          mime,
          dd_dest,
          url,
          outer_limits,
          changes,
          files,
          collection: nil
        )
          # e.g. 'DistorteD::Static::Image' or 'DistorteD::Static::Video'
          @tag_name = self.class.name.split('::').drop(1).join('::').to_sym.freeze

          # String path to Jekyll site root
          @base = base

          # String container dir (under `base`) of original file
          @dir = dir

          # String filename of original file
          @name = name

          # Set of MIME::Types of the original media file.
          @mime = mime

          # String path to media generation output dir
          # under Site.dest (which is currently unknown)
          @dd_dest = dd_dest

          # String destination URL for the post/page on which the media appears.
          @url = url

          # Config struct data down
          @outer_limits = outer_limits
          @changes = changes

          # Pre-generated Set of Hashes describing wanted files,
          # and a Set of just the String filenames to be generated.
          # I would prefer to generate this here in StaticFile land,
          # but Liquid needs them too for the templates.
          @files = files
          @filenames = files.map{|f| f[:name]}.to_set

          # Hello yes
          Jekyll.logger.debug(@tag_name, "#{base}/#{dir}/#{name} -> #{url}})")

          # Construct Jekyll::StaticFile with only the args it takes:
          super(
            site,
            base,
            dir,
            name,
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
