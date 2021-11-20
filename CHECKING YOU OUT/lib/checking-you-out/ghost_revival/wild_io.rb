require(-'forwardable') unless defined?(::Forwardable)
require(-'pathname') unless defined?(::Pathname)

module ::CHECKING::YOU::OUT::GHOST_REVIVAL

  # Wrap `::Pathname`s alongside their `::IO` stream (from `#open`) and their extname-glob
  # so we can pass the entire thing around as a single unit.
  #
  # A lot of `::Pathname` is in C: https://github.com/ruby/ruby/blob/master/ext/pathname/pathname.c
  #             …and some in Ruby: https://github.com/ruby/ruby/blob/master/ext/pathname/lib/pathname.rb
  # Note the `rb_ext_ractor_safe(true);` :D
  #
  # TODO: Implement some sort of sliding-window `::IO#read` functionality here
  #       so `SequenceCat#=~` doesn't have to allocate and `#read` a throwaway byte `::String`
  #       for every matching attempt.
  #       https://blog.appsignal.com/2018/07/10/ruby-magic-slurping-and-streaming-files.html
  Wild_I∕O = ::Struct.new(:pathname, :stream, :stick_around) do

    def initialize(pathname)
      super(pathname.is_a?(::Pathname) ? pathname : ::Pathname.new(pathname), nil, nil)
    end

    def stream
      if self[:pathname].exist? and not self[:pathname].directory? then
        self[:stream] ||= self[:pathname].open(mode=::File::Constants::RDONLY|::File::Constants::BINARY).tap {
          # Tell the GC to close this stream when it goes out of scope.
          _1.autoclose = true
        }
      else nil
      end
    end

    def stick_around
      self[:stick_around] ||= ::CHECKING::YOU::OUT::StickAround.new(self[:pathname].to_s)
    end

    extend(::Forwardable)
    def_instance_delegators(
      :pathname,
      *::Pathname::instance_methods(false).difference(self.instance_methods(false))
    )

    # The `::Pathname` is the only one assumed to be set at all times, so `#hash` based on that.
    def hash; self[:pathname].hash; end

    # Empty out the `::Struct` so it can be re-used.
    def clear; self.tap { |get_wild| get_wild.members.each { |m| get_wild[m] = nil } }; end

    def eql?(otra)
      # TODO: Add `::IO`,`::String` etc here.
      case otra
      when ::Pathname then self[:pathname].eql?(otra)
      else super(otra)
      end
    end
    alias_method(:==, :eql?)

  end  # Wild_I∕O

end  # module ::CHECKING::YOU::IN::GHOST_REVIVAL
