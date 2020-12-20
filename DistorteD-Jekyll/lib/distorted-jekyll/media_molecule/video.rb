require 'distorted/molecule/video'


module Jekyll
  module DistorteD
    module Molecule
      module Video

        include Cooltrainer::DistorteD::Molecule::Video

        def render_to_output_buffer(context, output)
          begin
            output << parse_template.render({
              'name' => @name,
              'basename' => File.basename(@name, '.*'),
              'path' => @url,
              'caption' => abstract(:caption),
            })
          rescue Liquid::SyntaxError => l
            unless Jekyll.env == 'production'.freeze
              output << parse_template(name: 'error_code'.freeze).render({
                'message' => l.message,
              })
            end
          end
          output
        end

        # Return a Set of extant video variations due to inability/unwillingness
        # to exactly predict GStreamer's HLS/DASH segment output naming
        # even if we are controlling all variables like segment length etc.
        # This implementation may give stale segments but will at least speed
        # up site generation by not having to regenerate the video every time.
        def destinations(dest)
          wanted = Set[]
          if Dir.exist?(File.join(dest, @relative_dest))
            hls_dir = File.join(dest, @relative_dest, "#{basename}.hls")
            if Dir.exist?(hls_dir)
              wanted.merge(Dir.entries(hls_dir).to_set.map{|f| File.join(hls_dir, f)})
            end
          end
          wanted
        end

        def modified?
          # We can't use the standard Static::State#modified? here until
          # I figure out how to cleanly get a duplicate of what would be
          # the generated filenames from GStreamer's sink.
          #
          # For now for the sake of speeding up my site generation
          # I'll assume not-modified that if the output variant (e.g. DASH/HLS)
          # container dir exists and contains at least two files:
          # the playlist and at least one segment.
          #
          # Hacky HLS-only right now until dashsink2 lands in upstream Gst.
          #
          # Assume modified for the sake of freshness :)
          modified = true

          site_dest = the_setting_sun(:destination).to_s
          if Dir.exist?(site_dest)

            dd_dest = File.join(site_dest, @relative_dest)
            if Dir.exist?(dd_dest)

              hls_dir = File.join(dd_dest, "#{basename}.hls")
              if Dir.exist?(hls_dir)
                need_filez = Set["#{basename}.m3u8"]
                var_filez = Dir.entries(hls_dir).to_set
                if need_filez.subset?(var_filez) and var_filez.count > 2
                  modified = false
                end
              end

            end
          end
          Jekyll.logger.debug("#{@name} modified?",  modified)
          modified
        end

      end
    end
  end
end
