require 'set'

require 'distorted/checking_you_out'
require 'distorted/injection_of_love'

require 'distorted/modular_technology/gstreamer'


module Cooltrainer
  module DistorteD
    module Video

      LOWER_WORLD = CHECKING::YOU::IN('video/mp4')

      # Attributes for our <video>.
      # Automatically enabled as attrs for DD Liquid Tag.
      # https://developer.mozilla.org/en-US/docs/Web/HTML/Element/video#Attributes
      ATTRIBUTES = Set[:caption]

      # Defaults for HTML Element attributes.
      # Not every attr has to be listed here.
      # Many need no default and just won't render.
      ATTRIBUTES_DEFAULT = {}
      ATTRIBUTES_VALUES = {}

      def generate_dash
        orig_dest = @dest
        orig_path = @src

        FileUtils.mkdir_p(File.dirname(orig_dest))

        hls_dest = File.join(File.dirname(orig_dest), @basename + '.dash')
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
        pipeline, error = Gst.parse_launch("filesrc name=src ! decodebin name=demux ! videoconvert ! vaapih264enc ! queue2 ! h264parse ! queue2 ! mux.video dashsink name=mux max-files=0 playlist-length=0 target-duration=2 demux. ! audioconvert ! voaacenc ! queue2 ! mux.audio")

        if pipeline.nil?
          Jekyll.logger.error(@tag_name, "Parse error: #{error.message}")
          return false
        end

        filesrc = pipeline.get_by_name('src')
        filesrc.location = orig_path

        hls_playlist = "#{hls_dest}/#{@basename}.m3u8"
        hls = pipeline.get_by_name('mux')
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

      end

      include Cooltrainer::DistorteD::Technology::GStreamer
      include Cooltrainer::DistorteD::InjectionOfLove

    end  # Video
  end  # DistorteD
end  # Cooltrainer
