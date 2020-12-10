require 'set'

require 'distorted/checking_you_out'

require 'distorted/modular_technology/gstreamer'


module Cooltrainer; end
module Cooltrainer::DistorteD; end
module Cooltrainer::DistorteD::Molecule; end
module Cooltrainer::DistorteD::Molecule::Video

  LOWER_WORLD = CHECKING::YOU::IN('video/mp4').to_hash

  include Cooltrainer::DistorteD::Technology::GStreamer

end  # Video
