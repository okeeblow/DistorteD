require 'tmpdir'

require 'distorted-floor/invoker'
require 'distorted-floor/checking_you_out'
using ::DistorteD::CHECKING::YOU::OUT

# https://saveriomiroddi.github.io/Installing-ruby-tk-bindings-gem-on-ubuntu/
#
# Require `tk` last to avoid massive slowdown if `RUN_EVENTLOOP_ON_MAIN_THREAD == false`:
# https://github.com/ruby/tk/issues/26
require 'tk'


module Cooltrainer; end
module Cooltrainer::DistorteD; end
class Cooltrainer::DistorteD::Booth

  class TkDistorteD

    # Stub these until refactoring this into Glimmer.
    def the_setting_sun(...); nil; end
    def context_arguments(...); nil; end

    include Cooltrainer::DistorteD::Invoker

    # Returns an absolute String path to the source file.
    def path
      File.expand_path(@name)
    end

    def initialize(src)
      @name = src
    end
  end


  def initialize(argv)
    @name = argv.shift
    unless @name
      raise ArgumentError.new('Please provide a media file to open.')
    end

    # Tk's only built-in color image format.
    type = ::CHECKING::YOU::OUT::from_ietf_media_type('image/x-portable-pixmap')
    change = Cooltrainer::Change.new(type, src: @name)

    # Init DistorteD for our source file.
    tkd = TkDistorteD.new(File.expand_path(@name))

    # Create a temporary directory that will be removed
    # after the execution of this block.
    Dir.mktmpdir do |temp_dir|
      # Write our PPM file to the temp directory
      tkd.send(type.distorted_file_method, temp_dir, change, **{})

      # Create a root window
      root = TkRoot.new(
        :title => "#{File.basename(@name)} (#{File.dirname(@name)}) — DistorteD",
      )

      # Create a container to display our PPM from the temp path
      image = TkPhotoImage.new
      image.file(change.paths(temp_dir).first)

      # The Image frame has to be in a Label sized to match.
      label = TkLabel.new(root)
      label.image = image
      label.place(:height => image.height, :width => image.width)

      # And the main window should be resized as well.
      root.configure(:width => image.width, :height => image.height)
      Tk.mainloop
    end

  end

end
