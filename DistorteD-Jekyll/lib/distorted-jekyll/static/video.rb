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
      pipeline, error = Gst.parse_launch("filesrc name=src ! decodebin name=demux ! videoconvert ! vaapih264enc ! queue2 ! mpegtsmux name=mux ! hlssink name=hls max-files=0 playlist-length=60 target-duration=2 allowcache=yes demux. ! audioconvert ! voaacenc ! queue2 ! mux.")

      if pipeline.nil?
        Jekyll.logger.error(@tag_name, "Parse error: #{error.message}")
        return false
      end

      filesrc = pipeline.get_by_name('src')
      filesrc.location = orig_path

      hls = pipeline.get_by_name('hls')
      #hls.playlist_root = hls_dest
      hls.location = "#{hls_dest}/#{@basename}%05d.ts"
      hls.playlist_location = "#{hls_dest}/#{@basename}.m3u8"

      pipeline.play

      # Play until End Of Stream
      event_loop(pipeline)

      pipeline.stop
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
