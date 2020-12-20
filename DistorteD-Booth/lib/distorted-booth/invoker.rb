# https://saveriomiroddi.github.io/Installing-ruby-tk-bindings-gem-on-ubuntu/
require 'tk'
require 'tempfile'

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

    temp = Tempfile.new([File.basename(@name, '.*'), '.ppm'])
    type = CHECKING::YOU::OUT['image/x-portable-pixmap']

    tkd = TkDistorteD.new(File.expand_path(@name))
    tkd.send(type.distorted_method, temp.path)
    temp.close

    root = TkRoot.new(
      :title => "#{File.basename(@name)} (#{File.dirname(@name)}) — DistorteD",
    )

    image = TkPhotoImage.new
    image.file(temp.path)

    label = TkLabel.new(root) 
    label.image = image
    label.place(:height => image.height, :width => image.width)

    root.configure(:width => image.width, :height => image.height)
    Tk.mainloop
  end

end
