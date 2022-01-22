require 'set'

require 'distorted/checking_you_out'
using ::DistorteD::CHECKING::YOU::OUT

require('xross-the-xoul/version') unless defined?(::XROSS::THE::Version::TripleCounter)
GST_MINIMUM_VER = ::XROSS::THE::Version::TripleCounter.new(1, 18, 0)

begin
  require 'gst'
  GST_AVAILABLE_VER = ::XROSS::THE::Version::TripleCounter.new(*(Gst.version))
  unless GST_AVAILABLE_VER >= GST_MINIMUM_VER
    raise LoadError.new(
      "DistorteD needs GStreamer #{GST_MINIMUM_VER}, but the available version is '#{Gst.version_string}'"
    )
  end
rescue LoadError => le
  raise unless le.message =~ /libgst/

  # Multiple OS help
  help = <<~INSTALL

  Please install the GStreamer library for your system, version #{GST_MINIMUM_VER} or later.
  INSTALL

  # Re-raise with install message
  raise $!, "#{help}\n#{$!}", $!.backtrace
end


module Cooltrainer; end
module Cooltrainer::DistorteD; end
module Cooltrainer::DistorteD::Technology; end
module Cooltrainer::DistorteD::Technology::GStreamer

  OUTER_LIMITS = Set[
    'application/dash+xml',
    'application/vnd.apple.mpegurl',
    'video/mp4',
  ].map(&::CHECKING::YOU::OUT::method(:from_ietf_media_type))


  def write_video_mp4(dest_root, change)
    copy_file(change.paths(dest_root).first)
  end

  def write_application_dash_xml(dest, *a, **k)
    begin
      segment_dest = File.join(File.dirname(dest), "#{basename}.dash", '/')
      #segment_dest = segment_dest.sub("#{@base}/", '')
      FileUtils.mkdir_p(segment_dest)
      Jekyll.logger.debug(@tag_name, "Re-muxing #{path} to #{segment_dest}")

      # https://gstreamer.freedesktop.org/documentation/tools/gst-launch.html?gi-language=c#pipeline-description
      # TODO: Convert this from parse_launch() pipeline notation to Element objects
      # TODO: Get source video duration/resolution/etc and use it to compute a
      #  value for `target-duration`.
      # TODO: Also support urldecodebin for remote media.
      pipeline, error = Gst.parse_launch("dashsink name=mux  filesrc name=src ! decodebin name=demux ! audioconvert ! avenc_aac ! mux.audio_0 demux. ! videoconvert ! x264enc ! mux.video_0")

      if pipeline.nil?
        Jekyll.logger.error(@tag_name, "Parse error: #{error.message}")
        return false
      end

      filesrc = pipeline.get_by_name('src')
      filesrc.location = path

      mux = pipeline.get_by_name('mux')
      mux.mpd_filename = File.basename(dest)
      mux.target_duration = 3
      #mux.segment_tpl_path = "#{segment_dest}/#{basename}%05d.mp4"
      mux.mpd_root_path = segment_dest
      Jekyll.logger.warn('MPD ROOT PATH', mux.get_property('mpd-root-path'))

      # typedef enum
      # {
      #   GST_DASH_SINK_MUXER_TS = 0,
      #   GST_DASH_SINK_MUXER_MP4 = 1,
      # } GstDashSinkMuxerType;
      mux.muxer = 1

      pipeline.play

      # Play until End Of Stream
      event_loop(pipeline)

      pipeline.stop

    rescue Gst::ParseError::NoSuchElement
      raise
    end
  end

  def write_application_vnd_apple_mpegurl(dest, *a, **k)
    begin
      orig_dest = dest
      orig_path = path

      FileUtils.mkdir_p(File.dirname(orig_dest))

      hls_dest = File.join(File.dirname(orig_dest), basename + '.hls')
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
      # TODO: Also support urldecodebin for remote media.
      pipeline, error = Gst.parse_launch("filesrc name=src ! decodebin name=demux ! videoconvert ! x264enc ! queue2 ! h264parse ! queue2 ! mux.video hlssink2 name=mux max-files=0 playlist-length=0 target-duration=2 demux. ! audioconvert ! faac ! queue2 ! mux.audio")

      if pipeline.nil?
        Jekyll.logger.error(@tag_name, "Parse error: #{error.message}")
        return false
      end

      filesrc = pipeline.get_by_name('src')
      filesrc.location = orig_path

      hls_playlist = "#{hls_dest}/#{basename}.m3u8"
      hls = pipeline.get_by_name('mux')
      hls.location = "#{hls_dest}/#{basename}%05d.ts"
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
    rescue Gst::ParseError::NoSuchElement
      raise
    end
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
