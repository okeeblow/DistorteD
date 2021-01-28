module Cooltrainer

  # Fun Ruby Fact™: `false` is always object_id 0
  # https://skorks.com/2009/09/true-false-and-nil-objects-in-ruby/
  # irb(main):650:0> true.object_id
  # => 20
  # irb(main):651:0> false.object_id
  # => 0
  BOOLEAN_VALUES = Set[false, true]


  # Struct to encapsulate all the data needed to perform one (1) MIME::Type transformation
  # of a source media file into any supported MIME::Type, possibly even the same type as input.
  Change = Struct.new(:type, :src, :basename, :molecule, :tag, :breaks, :atoms, keyword_init: true) do

    # Customize the destination filename and other values before doing the normal Struct setup.
    def initialize(type, src: nil, molecule: nil, tag: nil, breaks: Array.new, **atoms)
      # `name` might have a leading slash if referenced as an absolute path as the Tag.
      basename = File.basename(src, '.*'.freeze).reverse.chomp('/'.freeze).reverse

      # Set the &default_proc on the kwarg-glob Hash instead of making a new Hash,
      atoms.default_proc = lambda { |h,k| h[k] = Cooltrainer::Atom.new }
      atoms.transform_values {
        # We might get Atoms already instantiated, but do it for any that aren't.
        # We won't have a default value for them in that case.
        |v| v.is_a?(Cooltrainer::Atom) ? atom : Cooltrainer::Atom.new(v, nil)
      }.each_key { |k|
        # Define accessors for context-specific :atoms keys/values that aren't normal Struct members.
        self.singleton_class.define_method(k) { self[:atoms]&.fetch(k, nil)&.get }
        self.singleton_class.define_method("#{k}=".to_sym) { |v| self[:atoms][k] = v }
      }

      # And now back to your regularly-scheduled Struct
      super(type: type, src: src, basename: basename, molecule: molecule, tag: tag, breaks: breaks, atoms: atoms)
    end

    # Returns the Change Type's :preferred_extension as a String with leading dot (.)
    def extname
      dot = '.'.freeze unless type.preferred_extension.nil? || type.preferred_extension&.empty?
      "#{dot}#{type.preferred_extension}"
    end

    # Returns an Array[String] of filenames this Change should generate,
    # one 'full'/'original' plus any limit-breaks,
    # e.g. ["DistorteD.png", "DistorteD-333.png", "DistorteD-555.png", "DistorteD-888.png", "DistorteD-1111.png"]
    def names
      Array[''.freeze].concat(self[:breaks]).map { |b|
        filetag = (b.nil? || b&.to_s.empty?) ? ''.freeze : '-'.concat(b.to_s)
        "#{self[:basename]}#{"-#{self.tag}" unless self.tag.nil?}#{filetag}#{extname}"
      }
    end

    # Returns a String describing the :names but rolled into one,
    # e.g. "IIDX-turntable-(400|800|1500).png"
    def name
      break_tags = self[:breaks].length > 1 ? "-(#{self[:breaks].join('|'.freeze)})" : ''.freeze
      "#{self.basename}#{"-#{self.tag}" unless self.tag.nil?}#{break_tags}#{self.extname}"
    end

    # Returns an Array[String] of all absolute destination paths this Change should generate,
    # given a root destination directory.
    def paths(dest_root = ''.freeze)  # Empty String will expand to current working directory
      output_dir = self[:atoms]&.fetch(:dir, ''.freeze)
      return self.names.map { |n| File.join(File.expand_path(dest_root), output_dir, n) }
    end

    # Returns a String absolute destination path for only one limit-break.
    def path(dest_root, break_value)
      output_dir = self[:atoms]&.fetch(:dir, ''.freeze)
      return File.join(File.expand_path(dest_root), output_dir, "#{self.basename}#{"-#{self.tag}" unless self.tag.nil?}-#{break_value}#{self.extname}")
    end

    # A generic version of Struct#to_hash was rejected with good reason,
    # but I'm going to use it here because I want the implicit Struct-to-Hash
    # conversion to let me destructure these Structs with a double-splat:
    # https://bugs.ruby-lang.org/issues/4862
    #
    # Defining this method causes Ruby 2.7 to emit a "Using the last argument as keyword parameters is deprecated" warning
    # if this Struct is passed to a method as the final positional argument! Ruby 2.7 will actually do the
    # conversion when calling the method in that scenario, causing incorrect behavior to methods expecting Struct.
    # This is why DD-Floor's `:write` and DD-Jekyll's `:render_to_output_buffer` pass an empty kwargs Hash.
    # https://www.ruby-lang.org/en/news/2019/12/12/separation-of-positional-and-keyword-arguments-in-ruby-3-0/
    def to_hash  # Implicit
      Hash[self.members.reject{|m| m == :atoms}.zip(self.values.reject{|v| v.is_a?(Hash)})].merge(self[:atoms].transform_values(&:get))
    end
    # Struct#to_h does exist in stdlib, but redefine its behavior to match our `:to_hash`.
    def to_h  # Explicit
      Hash[self.members.reject{|m| m == :atoms}.zip(self.values.reject{|v| v.is_a?(Hash)})].merge(self[:atoms].transform_values(&:get))
    end
    def dig(*keys); self.to_hash.dig(*keys); end

    # Support setting Atoms that were not defined at instantiation.
    def method_missing(meth, *a, **k, &b)
      # Are we a setter?
      if meth.to_s[-1] == '='.freeze
        # Set the :value of an existing Atom Struct
        self[:atoms][meth.to_s.chomp('='.freeze).to_sym].value = a.first
      else
        self[:atoms]&.fetch(meth, nil)
      end
    end

  end  # Struct Change


  # Struct to wrap just the user and default values for a Compound or just for freeform usage.
  Atom = Struct.new(:value, :default) do
    # Return a value if set, otherwise a default. Both can be `nil`.
    def get; self.value || self.default; end
    # Override these default Struct methods with ones that reference our :get
    def to_s; self.get.to_s; end    # Explicit
    def to_str; self.get.to_s; end  # Implicit
    # Send any unknown message through to a value/default.
    def method_missing(meth, *a, **k, &b); self.get.send(meth, *a, **k, &b); end
  end

end
