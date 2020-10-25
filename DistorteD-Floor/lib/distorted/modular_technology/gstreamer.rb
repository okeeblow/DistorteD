require 'set'

require 'distorted/checking_you_out'

require 'distorted/modular_technology/triple_counter'
GST_MINIMUM_VER = TripleCounter.new(1, 18, 0)

begin
  require 'gst'
  GST_AVAILABLE_VER = TripleCounter.new(*(Gst.version))
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

  OUTER_LIMITS = CHECKING::YOU::IN(Set[
    'application/dash+xml',
    'application/vnd.apple.mpegurl',
    'video/mp4',
  ])


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
