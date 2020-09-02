require 'set'

require 'distorted/checking_you_out'

require 'distorted/modular_technology/vips_load'
require 'distorted/modular_technology/vips_save'


module Cooltrainer; end
module Cooltrainer::DistorteD; end
module Cooltrainer::DistorteD::Technology; end
module Cooltrainer::DistorteD::Technology::Vips

  include Cooltrainer::DistorteD::Technology::VipsSave
  include Cooltrainer::DistorteD::Technology::VipsLoad

end
