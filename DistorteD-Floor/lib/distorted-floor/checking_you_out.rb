require 'set'

# CYO encapsulate all concepts related to media file identification for DistorteD!

# General media type resources:
# https://www.iana.org/assignments/media-types/media-types.xhtml


# The Gem `ruby-mime-types` and its associated `mime-types-data` provide our core classes:
# https://github.com/mime-types/ruby-mime-types
require 'mime/types'
#
# - Its MIME Types database ensures I don't have to constantly update DD with
#   new filetypes as they are invented, like how AVIF is still currently brand-new as of 2021.
# - Our main Type search method — :OUT() — wraps `MIME::Types.type_for`/`MIME::Types[]`
#   to identify media types based on filename alone (e.g. even for hypothetical files).
# - The Object we give callers will be a `MIME::Type`, not anything wrapped/renamed.
# - I use its Loader class and YAML structure to ship additional Type definitions local to DD.
#
# NOTE: Type objects returned from the unwrapped MIME::Types interfaces will not have equality
#       with instances of the same media type from CYO! This is because we load our own database.
#   irb(main)> MIME::Types['image/jpeg'].object_id
#   => 136400
#   irb(main)> CHECKING::YOU::OUT['image/jpeg'].object_id
#   => 90800


# The Gem `ruby-filemagic` provides the ability to inspect the magic bytes of actual on-disk files.
# https://github.com/blackwinter/ruby-filemagic
# http://blackwinter.github.io/ruby-filemagic/
#
# NOTE: Unmaintained!
# https://github.com/blackwinter/ruby-filemagic/commit/e1f2efd07da4130484f06f58fed016d9eddb4818
#
# Might consider replacing this with an FFI filemagic to eliminate the native-code compilation.
# https://rubygems.org/gems/glongman-ffiruby-filemagic/
# https://stuart.com/blog/ruby-bindings-extensions/
require 'ruby-filemagic'


# Monkey-patch some DistorteD-specific methods into MIME::Type objects.
module MIME
  class Type

    # Provide a few variations on the base :distorted_method for mixed workflows
    # where it isn't feasible to overload a single method name and call :super.
    # Jekyll, for example, renders its output markup upfront, collects all of
    # the StaticFiles (or StaticStatic-includers, in our case), then calls their
    # :write methods all at once after the rest of the site is built,
    # and this precludes us from easily sharing method names between layers.
    DISTORTED_METHOD_PREFIXES = Hash[
      :buffer => 'to'.freeze,
      :file => 'write'.freeze,
      :template => 'render'.freeze,
    ]
    SUB_TYPE_SEPARATORS = /[-_+\.]/

    # Returns a Symbol name of the method that should return a String buffer containing the file in this Type.
    def distorted_buffer_method; "#{DISTORTED_METHOD_PREFIXES[:buffer]}_#{distorted_method_suffix}".to_sym; end

    # Returns a Symbol name of the method that should write a file of this Type to a given path on a filesystem.
    def distorted_file_method; "#{DISTORTED_METHOD_PREFIXES[:file]}_#{distorted_method_suffix}".to_sym; end

    # Returns a Symbol name of the method that should returns a context-appropriate Object
    # for displaying the file as this Type.
    # Might be e.g. a String buffer containing Rendered Liquid in Jekylland,
    # or a Type-appropriate frame in some GUI toolkit in DD-Booth.
    def distorted_template_method; "#{DISTORTED_METHOD_PREFIXES[:template]}_#{distorted_method_suffix}".to_sym; end

    # Returns an Array[Array[String]] of human-readable keys we can use for our YAML config,
    # e.g. :media_type 'image' & :sub_type 'svg+xml' would be split to ['image', 'svg'].
    # `nil` `:sub_type`s will just be compacted out.
    # Every non-nil :media_type will also request a key path [media_type, '*']
    # to allow for similar-type defaults, e.g. every image type outputting a fallback.
    def settings_paths; [[self.media_type, '*'.freeze], [self.media_type, self.sub_type&.split('+'.freeze)&.first].compact]; end

    private

    # Provide a consistent base method name for context-specific DistorteD operations.
    def distorted_method_suffix
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
      "#{self.media_type}_#{self.sub_type.gsub(SUB_TYPE_SEPARATORS, '_'.freeze)}"
    end  # distorted_method_suffix
  end
end


module CHECKING
  class YOU

    # Returns a single Type with Array-style access.
    class OUT
      def self.[](type)
        CHECKING::YOU::types[type].first
      end
    end

    # Returns a Set of MIME::Type for a given file path, by default only
    # based on the file extension. If the file extension is unavailable—
    # or if `so_deep` is enabled—the `path` will be used as an actual
    # path to look at the magic bytes with ruby-filemagic.
    def self.OUT(path, so_deep: false, only_one_test: false)
      return Set[] if path.nil?
      if not (only_one_test || types.type_for(path).empty?)
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
      elsif (so_deep && path[0] != '.'.freeze)  # Support taking hypothetical file extensions (e.g. '.jpg') without stat()ing anything.
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
        end  # FileMagic.open
      else
        # TODO: Warn here that we may need a custom type!
        #p "NO MATCH FOR #{path}"
        Set[]
      end  # if
    end  # self.OUT()

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
