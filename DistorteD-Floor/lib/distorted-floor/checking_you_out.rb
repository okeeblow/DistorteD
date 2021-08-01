require 'checking-you-out'


module DistorteD; end
module DistorteD::CHECKING; end
module DistorteD::CHECKING::YOU; end
module DistorteD::CHECKING::YOU::OUT

  refine ::CHECKING::YOU::OUT::singleton_class do

    # NOTE: We can't define constants in refinements without getting a
    # "not defined at the refinement, but at the outer class/module" Warning.

    # Provide a few variations on the base :distorted_method for mixed workflows
    # where it isn't feasible to overload a single method name and call :super.
    # Jekyll, for example, renders its output markup upfront, collects all of
    # the StaticFiles (or StaticStatic-includers, in our case), then calls their
    # :write methods all at once after the rest of the site is built,
    # and this precludes us from easily sharing method names between layers.
    def distorted_method_prefixes
      @distorted_method_prefixes ||= Hash[
        :buffer => 'to'.freeze,
        :file => 'write'.freeze,
        :open => 'open'.freeze,
        :template => 'render'.freeze,
      ]
    end

    def type_separators
      @type_separators ||= /[\/\-_+\.=;]/
    end

  end


  refine ::CHECKING::YOU::OUT do

    # Returns a Symbol name of the method that should return a loaded imtermediate structure of some sort, e.g. a Vips::Image.
    def distorted_open_method; "#{self.class.distorted_method_prefixes[:open]}_#{distorted_method_suffix}".to_sym; end

    # Returns a Symbol name of the method that should return a String buffer containing the file in this Type.
    def distorted_buffer_method; "#{self.class.distorted_method_prefixes[:buffer]}_#{distorted_method_suffix}".to_sym; end

    # Returns a Symbol name of the method that should write a file of this Type to a given path on a filesystem.
    def distorted_file_method; "#{self.class.distorted_method_prefixes[:file]}_#{distorted_method_suffix}".to_sym; end

    # Returns a Symbol name of the method that should returns a context-appropriate Object
    # for displaying the file as this Type.
    # Might be e.g. a String buffer containing Rendered Liquid in Jekylland,
    # or a Type-appropriate frame in some GUI toolkit in DD-Booth.
    def distorted_template_method; "#{self.class.distorted_method_prefixes[:template]}_#{distorted_method_suffix}".to_sym; end

    # Returns an Array[Array[String]] of human-readable keys we can use for our YAML config,
    # e.g. :phylum 'image' & :genus 'svg+xml' would be split to ['image', 'svg'].
    # `nil` `:genus` will just be compacted out.
    # Every non-nil :phylum will also request a key path [media_type, '*']
    # to allow for similar-type defaults, e.g. every image type outputting a fallback.
    def settings_paths; [[self.phylum, -?*], [self.phylum, self.genus&.split(-?+)&.first].compact]; end

    private

    # Provide a consistent base method name for context-specific DistorteD operations.
    def distorted_method_suffix
      # Standardize ::CHECKING::YOU::OUT to DistorteD method mapping
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
      self.to_s.gsub(self.class.type_separators, -?_)
    end
  end
end
