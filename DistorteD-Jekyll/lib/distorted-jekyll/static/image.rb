require 'distorted/image'
require 'distorted-jekyll/static/state'

module Jekyll
  module DistorteD
    module Static
      class Image < Jekyll::DistorteD::Static::State

        # HACK HACK HACK
        # Jekyll does not pass this method a site.dest like it does write() and
        # others, but I want to be able to short-circuit here if all the
        # to-be-generated files already exist.
        # Take advantage of the fact the destdir will be `_site` 99% of the time.
        def modified?
          modified = true
          # TODO: Support more than one Site
          site_dest = File.join(@base, '_site')
          if Dir.exist?(site_dest)
            dd_dest = dd_dest(site_dest)
            if Dir.exist?(dd_dest)
              existing_files = Dir.entries(dd_dest).to_set
              if @filenames - existing_files
                Jekyll.logger.debug(@name, "Missing variations: #{@filenames - existing_files}")
              end
              # TODO: Make this smarter. It's not enough that all the generated
              # filenames should exist. Try a few more ways to detect subtler
              # "changes to the source file since generation of variations.
              if @filenames.subset?(existing_files)
                modified = false
              end
            end
          end
          Jekyll.logger.debug("#{@name} modified?",  modified)
          return modified
        end

        # dest: string realpath to `_site_` directory
        def write(dest)
          return false if File.exist?(path) && !modified?
          self.class.mtimes[path] = mtime

          # Create any directories to the depth of the intended destination.
          FileUtils.mkdir_p(dd_dest(dest))

          distorted = Cooltrainer::DistorteD::Image.new(
            path,
            dest: dd_dest(dest),
            filenames: @filenames,
          )

          Jekyll.logger.debug(@tag_name, "Rotating #{@name} if tagged.")
          distorted.rotate(angle: :auto)

          distorted.types = @types
          distorted.dimensions = @dimensions

          Jekyll.logger.debug(@tag_name, "Adding dimensions #{distorted.dimensions}")

          distorted.generate

          true
        end

      end  # Image
    end  # Static
  end  # DistorteD
end  # Jekyll
