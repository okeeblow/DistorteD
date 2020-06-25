require 'set'

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
          return false if File.exist?(path) && !modified?
          self.class.mtimes[path] = mtime

          distorted = Cooltrainer::DistorteD::Video.new(path, orig_dest, basename)

          distorted.generate
        end

        def modified?
          # We can't use the standard Static::State#modified? here until
          # I figure out how to cleanly get a duplicate of what would be
          # the generated filenames from GStreamer's sink.
          # For now for the sake of speeding up my site generation
          # I'll assume not-modified that if the output variant (e.g. DASH/HLS)
          # container dir exists and contains at least two files:
          # the playlist and at least one segment.
          # Hacky HLS-only right now until dashsink2 lands in upstream Gst.
          var_dir = "#{@dir}.hls"
          if Dir.exist?(@dir)
            need_filez = Set["#{basename}.m3u8"]
            var_filez = Dir.entries(@dir).to_set
            mod = need_filez.subset?(var_filez) and var_filez.count > 2
            Jekyll.logger.debug("#{@name} modified?",  mod)
            return mod
          end
        end

      end  # Video
    end  # Static
  end  # DistorteD
end  # Jekyll
