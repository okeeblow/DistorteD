require 'set'

require 'distorted-jekyll/molecule/abstract'


module Jekyll
  module DistorteD
    module Static
      class State < Jekyll::StaticFile

      include Jekyll::DistorteD::Molecule::Abstract

        def initialize(
          site,
          base,
          dir,
          name,
          mime,
          attrs,
          dd_dest,
          url,
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

          # Union Set of MIME::Types between the original media file
          # and the plugged MediaMolecule.
          @mime = mime

          # Attributes provided to our Liquid tag
          @attrs = attrs

          # String path to media generation output dir
          # under Site.dest (which is currently unknown)
          @dd_dest = dd_dest

          # String destination URL for the post/page on which the media appears.
          @url = url

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
          filenames.map{|f| File.join(dd_dest(dest), f)} << destination(dest)
        end

        # HACK HACK HACK
        # Jekyll does not pass this method a site.dest like it does write() and
        # others, but I want to be able to short-circuit here if all the
        # to-be-generated files already exist.
        def modified?
          # Assume modified for the sake of freshness :)
          modified = true

          site_dest = Jekyll::DistorteD::Floor::config(:destination).to_s
          if Dir.exist?(site_dest)

            dd_dest = dd_dest(site_dest)
            if Dir.exist?(dd_dest)

              # TODO: Make outputting the original file conditional.
              # Doing that will require changing the default href handling
              # in the template, Jekyll::DistorteD::Static::State.destinations,
              # as well as Cooltrainer::DistorteD::Image.generate
              wanted_files = Set[@name].merge(filenames)
              extant_files = Dir.entries(dd_dest).to_set

              # TODO: Make this smarter. It's not enough that all the generated
              # filenames should exist. Try a few more ways to detect subtler
              # "changes to the source file since generation of variations.
              if wanted_files.subset?(extant_files)
                Jekyll.logger.debug(@name, "All variations present: #{wanted_files}")
                modified = false
              else
                Jekyll.logger.debug(@name, "Missing variations: #{wanted_files - extant_files}")
              end

            end  # dd_dest.exists?
          end  # site_dest.exists?
          Jekyll.logger.debug("#{@name} modified?",  modified)
          return modified
        end

      end  # state
    end  # Static
  end  # DistorteD
end  # Jekyll
