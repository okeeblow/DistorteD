module Cooltrainer
  class DistortedFloor

    def self.image_name(orig, suffix = nil)
      if suffix
        File.basename(orig, '.*') + '-' + suffix + File.extname(orig)
      else
        orig
      end
    end

  end
end
