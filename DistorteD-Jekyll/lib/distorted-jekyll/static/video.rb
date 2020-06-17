require 'distorted/video'
require 'distorted-jekyll/static/state'

module Jekyll
  module DistorteD
    module Static
      class Video < Jekyll::DistorteD::Static::State

        # dest: string realpath to `_site_` directory
        def write(dest)
          orig_dest = destination(dest)

          # TODO: Make this smarter. Need to see if there's an easy way to
          # get a list of would-be-generated filenames from GStreamer.
          return false if File.exist?(src_path) && !modified?
          self.class.mtimes[path] = mtime

          distorted = Cooltrainer::DistorteD::Video.new(src_path, orig_dest, basename)

          distorted.generate
        end

      end
    end
  end
end
