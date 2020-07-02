require 'fileutils'
require 'set'

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
        def modified?
          # Assume modified for the sake of freshness :)
          modified = true

          # TODO: Support more than one Site
          site_dest = File.join(@base, '_site'.freeze)
          if Dir.exist?(site_dest)

            dd_dest = dd_dest(site_dest)
            if Dir.exist?(dd_dest)

              # TODO: Make outputting the original file conditional.
              # Doing that will require changing the default href handling
              # in the template, Jekyll::DistorteD::Static::State.destinations,
              # as well as Cooltrainer::DistorteD::Image.generate
              wanted_files = Set[@name].merge(@filenames)
              extant_files = Dir.entries(dd_dest).to_set

              # TODO: Make this smarter. It's not enough that all the generated
              # filenames should exist. Try a few more ways to detect subtler
              # "changes to the source file since generation of variations.
              if wanted_files.subset?(extant_files)
                modified = false
              else
                Jekyll.logger.debug(@name, "Missing variations: #{wanted_files - extant_files}")
              end

            end  # dd_dest.exists?
          end  # site_dest.exists?
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

          distorted.changes = @changes
          distorted.outer_limits = @outer_limits

          Jekyll.logger.debug(@tag_name, "Adding dimensions #{distorted.dimensions}")

          distorted.generate

          true
        end

      end  # Image
    end  # Static
  end  # DistorteD
end  # Jekyll
