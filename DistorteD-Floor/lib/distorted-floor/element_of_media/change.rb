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
  Change = Struct.new(:type, :src, :basename, :name, :molecule, :tag, :atoms, keyword_init: true) do

    # Customize the destination filename and other values before doing the normal Struct setup.
    def initialize(type, name: nil, molecule: nil, tag: nil, **atoms)
      # `name` might have a leading slash if referenced as an absolute path as the Tag.
      basename = File.basename(name, '.*'.freeze).reverse.chomp('/'.freeze).reverse
      src = name.dup
      # Don't change the filename of full-size variations
      filetag = (tag.nil? || tag&.to_s.empty?) ? ''.freeze : '-'.concat(tag.to_s)
      # Give our new file the extension defined by the Type instead of the one it came in with.
      dot = '.'.freeze unless type.preferred_extension.nil? || type.preferred_extension&.empty?
      name = "#{basename}#{filetag}#{dot}#{type.preferred_extension}"

      atoms.default_proc = lambda { |h,k| h[k] = Cooltrainer::Atom.new }
      # Define accessors for context-specific :atoms keys/values that aren't normal Struct members.
      atoms.transform_values {
        |v| v.is_a?(Cooltrainer::Atom) ? atom : Cooltrainer::Atom.new(v, nil)
      }.each_key{ |k|
        self.singleton_class.define_method(k) { self[:atoms]&.fetch(k, nil)&.get }
        self.singleton_class.define_method("#{k}=".to_sym) { |v| self[:atoms][k] = v }
      }

      # And now back to your regularly-scheduled Struct
      super(type: type, src: src, basename: basename, name: name, molecule: molecule, tag: tag, atoms: atoms)
    end

    def path(dest_root = ''.freeze)  # Empty String will expand to current working directory
      output_path = self[:atoms]&.fetch(:dir, nil).nil? ? self[:name] : File.join(self[:atoms]&.dig(:dir).get, self[:name])
      return File.join(File.expand_path(dest_root), output_path)
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
