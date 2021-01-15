# https://saveriomiroddi.github.io/Installing-ruby-tk-bindings-gem-on-ubuntu/
require 'tk'
require 'tmpdir'

require 'distorted/invoker'
require 'distorted/checking_you_out'

module Cooltrainer; end
module Cooltrainer::DistorteD; end
class Cooltrainer::DistorteD::Booth

  class TkDistorteD
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
    type = CHECKING::YOU::OUT['image/x-portable-pixmap']
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
