require 'distorted/media_molecule/video'


module Jekyll; end
module Jekyll::DistorteD; end
module Jekyll::DistorteD::Molecule; end
module Jekyll::DistorteD::Molecule::Video

  include Cooltrainer::DistorteD::Molecule::Video

  Cooltrainer::DistorteD::IMPLANTATION(:LOWER_WORLD, Cooltrainer::DistorteD::Molecule::Video).each_key { |type|
    define_method(type.distorted_template_method) { |change|
      Cooltrainer::ElementalCreation.new(:video_source, change, parents: Array[:video])
    }
  }

  # Override wanted-filenames method from StaticState with one that prevents our generated
  # video segments from being deleted.
  # This is still very hacky until I can guarantee/control the number of segments we get.
  def wanted_files
    dd_dest = File.join(the_setting_sun(:jekyll, :destination).to_s, @relative_dest)
    changes.each_with_object(Set[]) { |change, wanted|
      case change.type
      # Treat HLS and MPEG-DASH the same, with slightly different naming conventions.
      # Add their main playlist file, but then also glob any segments that happen to exist.
      when CHECKING::YOU::OUT['application/dash+xml']
        hls_dir = File.join(dd_dest, "#{basename}.hls")
        wanted.add(File.join(hls_dir, "#{basename}.m3u8"))
        if Dir.exist?(hls_dir)
          Dir.entries(hls_dir).to_set.subtract(Set["#{basename}.m3u8"]).each { |hls| wanted.add(File.join(hls_dir, hls)) }
        end
      when CHECKING::YOU::OUT['application/vnd.apple.mpegurl']
        dash_dir = File.join(dd_dest, "#{basename}.dash")
        wanted.add(File.join(dash_dir, "#{basename}.mpd"))
        if Dir.exist?(dash_dir)
          Dir.entries(dash_dir).to_set.subtract(Set["#{basename}.mpd"]).each { |dash| wanted.add(File.join(dash_dir, dash)) }
        end
      else
        # Treat any other type (including single-file video types) like normal.
        wanted.add(change.name)
      end
    }
  end

end  # Video
