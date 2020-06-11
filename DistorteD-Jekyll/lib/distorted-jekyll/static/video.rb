require 'distorted/video'
require 'distorted-jekyll/static/state'

module Jekyll
  module DistorteD
    class VideoFile < Jekyll::StaticState

      def initialize(
        site,
        base,
        dir,
        name,
        url,
        collection = nil
      )
        super 
      end


      # dest: string realpath to `_site_` directory
      def write(dest)
        orig_dest = destination(dest)
        return false if File.exist?(orig_path) && !modified?
        self.class.mtimes[path] = mtime

        distorted = Cooltrainer::DistorteD::Video.new(orig_path, orig_dest, @basename)

				distorted.generate
      end

    end
  end
end
