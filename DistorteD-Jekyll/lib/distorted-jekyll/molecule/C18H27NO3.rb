module Jekyll
  module DistorteD
    module Molecule
      module C18H27NO3
        def self.extended(base)
          Set[
            :MEDIA_TYPE,
            :MIME_TYPES,
            :ATTRS,
            :ATTRS_DEFAULT,
            :ATTRS_VALUES,
            :CONFIG_SUBKEY,
          ].each { |c|
            self.singleton_class.const_set(c, self.const_get(c))
          }
        end
      end
    end
  end
end
