
# Our custom Exceptions
require 'distorted/error_code'

# MIME::Typer
require 'distorted/checking_you_out'

# Set.to_hash
require 'distorted/monkey_business/set'
require 'set'


module Cooltrainer; end
module Cooltrainer::DistorteD; end
module Cooltrainer::DistorteD::Invoker

  @@loaded_molecules rescue begin
    Dir[File.join(__dir__, 'molecule', '*.rb')].each { |molecule| require molecule }
    @@loaded_molecules = true
  end

end
