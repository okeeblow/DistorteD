#!/usr/bin/env ruby
# Tell the user to install the shared library if it's missing.
begin
  require 'gst'
rescue LoadError => le
  # Only match libvips.so load failure
  raise unless le.message =~ /libvips.so/

  # Multiple OS help
  help = <<~INSTALL

  Please install the library.
  INSTALL

  # Re-raise with install message
  raise $!, "#{help}\n#{$!}", $!.backtrace
end

require 'formats/static_state'

module Jekyll
  # Tag-specific StaticFile child that handles thumbnail generation.
  class DistorteD::VideoFile < Jekyll::StaticState

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

      FileUtils.mkdir_p(File.dirname(orig_dest))

      hls_dest = File.join(File.dirname(orig_dest), @basename + '.hls')
      FileUtils.mkdir_p(hls_dest)
      Jekyll.logger.debug(@tag_name, "Re-muxing #{orig_path} to #{hls_dest}.")

      #FileUtils.rm(orig_dest) if File.exist?(orig_dest)
      if not File.file?(orig_dest)
        FileUtils.cp(orig_path, orig_dest)
      end

      # https://gstreamer.freedesktop.org/documentation/tools/gst-launch.html?gi-language=c#pipeline-description
      # TODO: Convert this from parse_launch() pipeline notation to Element objects
      # TODO: Get source video duration/resolution/etc and use it to compute a
      #  value for `target-duration`.
      pipeline, error = Gst.parse_launch("filesrc name=src ! decodebin name=demux ! videoconvert ! vaapih264enc ! queue2 ! h264parse ! mpegtsmux name=mux ! hlssink name=hls max-files=0 playlist-length=0 target-duration=2 demux. ! audioconvert ! voaacenc ! queue2 ! mux.")

      if pipeline.nil?
        Jekyll.logger.error(@tag_name, "Parse error: #{error.message}")
        return false
      end

      filesrc = pipeline.get_by_name('src')
      filesrc.location = orig_path

      hls_playlist = "#{hls_dest}/#{@basename}.m3u8"
      hls = pipeline.get_by_name('hls')
      hls.location = "#{hls_dest}/#{@basename}%05d.ts"
      hls.playlist_location = hls_playlist

      # TODO: config option for absolute vs relative segment URIs in the playlist.
      #hls.playlist_root = @url

      # TODO: dashsink support once there is a stable GStreamer release including it:
      # https://gitlab.freedesktop.org/gstreamer/gst-plugins-bad/merge_requests/704

      pipeline.play

      # Play until End Of Stream
      event_loop(pipeline)

      pipeline.stop

      # HACK HACK HACK: Replace X-ALLOW-CACHE line in playlist with YES.
      # This property does not seem to be exposed to the outside of hlssink:
      # https://cgit.freedesktop.org/gstreamer/gst-plugins-bad/tree/ext/hls/gsthlssink.c
      text = File.read(hls_playlist)
      File.write(hls_playlist, text.gsub(/^#EXT-X-ALLOW-CACHE:NO$/, '#EXT-X-ALLOW-CACHE:YES'))
    end

    def event_loop(pipeline)
      running = true
      bus = pipeline.bus

      while running
        message = bus.poll(Gst::MessageType::ANY, -1)

        case message.type
        when Gst::MessageType::EOS
          running = false
        when Gst::MessageType::WARNING
          warning, _debug = message.parse_warning
          Jekyll.logger.warning(@tag_name, warning)
        when Gst::MessageType::ERROR
          error, _debug = message.parse_error
          Jekyll.logger.error(@tag_name, error)
          running = false
        end
      end
    end

  end
end
