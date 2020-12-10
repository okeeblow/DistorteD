require 'set'

require 'distorted/checking_you_out'

require 'distorted/modular_technology/vips/load'
require 'distorted/modular_technology/vips/save'


module Cooltrainer; end
module Cooltrainer::DistorteD; end
module Cooltrainer::DistorteD::Technology; end
module Cooltrainer::DistorteD::Technology::Vips

  include Cooltrainer::DistorteD::Technology::Vips::Save
  include Cooltrainer::DistorteD::Technology::Vips::Load

end
