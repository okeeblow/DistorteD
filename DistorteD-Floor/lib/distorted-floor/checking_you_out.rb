require 'set'

require 'mime/types'
require 'ruby-filemagic'

module MIME
  class Type
    # Give MIME::Type objects an easy way to get the DistorteD saver method name.
    def distorted_method
      # Standardize MIME::Types' media_type+sub_type to DistorteD method mapping
      # by replacing all the combining characters with underscores (snake case)
      # to match Ruby conventions:
      # https://rubystyle.guide/#snake-case-symbols-methods-vars
      #
      # For the worst possible example, an intended outout Type of
      # "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      # (a.k.a. a MSWord `docx` file) would map to a DistorteD saver method
      # :to_application_vnd_openxmlformats_officedocument_wordprocessingml_document
      # which would most likely be defined by the :included method of a library-specific
      # module for handling OpenXML MS Office documents.
      "to_#{self.media_type}_#{self.sub_type.gsub(/[-+\.]/, '_'.freeze)}".to_sym
    end
  end
end

module CHECKING
  class YOU

    # Returns a single Type with Array-style access.
    class OUT
      def self.[](type)
        CHECKING::YOU::types[type]
      end
    end

    # Returns a Set of MIME::Type for a given file path, by default only
    # based on the file extension. If the file extension is unavailable—
    # or if `so_deep` is enabled—the `path` will be used as an actual
    # path to look at the magic bytes with ruby-filemagic.
    def self.OUT(path, so_deep: false)
      unless so_deep || types.type_for(path).empty?
        # NOTE: `type_for`'s return order is supposed to be deterministic:
        # https://github.com/mime-types/ruby-mime-types/issues/148
        # My use case so far has never required order but has required
        # many Set comparisons, so I am going to return a Set here
        # and possibly throw the order away.
        # In my experience the order is usually preserved anyway:
        # irb(main)> MIME::Types.type_for(File.expand_path('lol.ttf'))
        # => [#<MIME::Type: font/ttf>, #<MIME::Type: application/font-sfnt>, #<MIME::Type: application/x-font-truetype>, #<MIME::Type: application/x-font-ttf>]
        # irb(main)> MIME::Types.type_for('lol.ttf')).to_set
        # => #<Set: {#<MIME::Type: font/ttf>, #<MIME::Type: application/font-sfnt>, #<MIME::Type: application/x-font-truetype>, #<MIME::Type: application/x-font-ttf>}>
        return types.type_for(path).to_set
      else
        # Did we fail to guess any MIME::Types from the given filename?
        # We're going to have to look at the actual file
        # (or at least its first four bytes).
        FileMagic.open(:mime) do |fm|
          # The second argument makes fm.file return just the simple
          # MIME::Type String, e.g.:
          #
          # irb(main)>   fm.file('/home/okeeblow/IIDX-turntable.svg')
          # => "image/svg+xml; charset=us-ascii"
          # irb(main)>   fm.file('/home/okeeblow/IIDX-turntable.svg', true)
          # => "image/svg"
          #
          # However MIME::Types won't take short variants like 'image/svg',
          # so explicitly have FM return long types and split it ourself
          # on the semicolon:
          #
          # irb(main)> "image/svg+xml; charset=us-ascii".split(';').first
          # => "image/svg+xml"
          mime = types[fm.file(path, false).split(';'.freeze).first].to_set
        end
      end
    end

    # Returns a Set of MIME::Type objects matching a String search key of the
    # format MEDIA_TYPE/SUB_TYPE.
    # This can return multiple Types, e.g. 'font/collection' TTC/OTC variations:
    # [#<MIME::Type: font/collection>, #<MIME::Type: font/collection>]
    def self.IN(wanted_type_or_types)
      if wanted_type_or_types.is_a?(Enumerable)
        # Support taking a list of String types for Molecules whose Type support
        # isn't easily expressable as a single Regexp.
        types.select{ |type| wanted_type_or_types.include?(type.to_s) }
      else
        # Might be a single String or Regexp
        types[wanted_type_or_types, :complete => wanted_type_or_types.is_a?(Regexp)].to_set
      end
    end

    protected

    # Returns the MIME::Types container or loads one
    def self.types
      @@types ||= types_loader
    end

    # Returns a loaded MIME::Types container containing both the upstream
    # mime-types-data and our own local data.
    def self.types_loader
      container = MIME::Types.new

      # Load the upstream mime-types-data by providing a nil `path`:
      # path || ENV['RUBY_MIME_TYPES_DATA'] || MIME::Types::Data::PATH
      loader = MIME::Types::Loader.new(nil, container)
      # TODO: Log this once I figure out a nice way to wrap Jekyll logger too.
      #   irb> loader.load_columnar => #<MIME::Types: 2277 variants, 1195 extensions>
      loader.load_columnar

      # Change default JPEG file extension from .jpeg to .jpg
      # because it pisses me off lol
      container['image/jpeg'].last.preferred_extension = 'jpg'

      # Add a missing extension to MPEG-DASH manifests:
      #   irb> MIME::Types['application/dash+xml'].first
      #   => #<MIME::Type: application/dash+xml>
      #   irb> MIME::Types['application/dash+xml'].first.preferred_extension
      #   => nil
      # https://www.iana.org/assignments/media-types/application/dash+xml
      container['application/dash+xml'].last.preferred_extension = 'mpd'

      # Override the loader's path with the path to our local data directory
      # after we've loaded the upstream data.
      # :@path is set up in Loader::initialize and only has an attr_reader
      # but we can reach in and change it.
      loader.instance_variable_set(:@path, File.join(__dir__, 'types'.freeze))

      # Load our local types data. The YAML files are separated by type,
      # and :load_yaml will load all of them in the :@path we just set.
      # MAYBE: Integrate MIME::Types YAML conversion scripts and commit
      # JSON/Columnar artifacts for SPEEEEEED, but YAML is probably fine
      # since we will have so few custom types compared to upstream.
      # Convert.from_yaml_to_json
      # Convert::Columnar.from_yaml_to_columnar
      loader.load_yaml

      container
    end

  end
end
