require 'distorted/image'
require 'distorted-jekyll/static/state'

module Jekyll
  module DistorteD
    class ImageFile < Jekyll::StaticState

      def initialize(
        site,
        base,
        dir,
        name,
        url,
        collection = nil
      )
        super

        @dimensions = site.config['distorted']['image']
      end

      # dest: string realpath to `_site_` directory
      def write(dest)
        fullres_dest = destination(dest)
        return false if File.exist?(orig_path) && !modified?

        self.class.mtimes[path] = mtime

        FileUtils.mkdir_p(File.dirname(fullres_dest))
        FileUtils.rm(fullres_dest) if File.exist?(fullres_dest)

        distorted = Cooltrainer::DistorteD::Image.new(orig_path)

        Jekyll.logger.debug(@tag_name, "Rotating #{@name} if tagged.")
        distorted.rotate(:auto)


        dimensions = [{:tag => :full, :dest => fullres_dest}]

        for d in @dimensions
          dimension = {
            :width => d['width'],  # Convert to AR-aware height-fit
            :crop => @crop&.to_sym || :attention,
            :tag => d['tag'].to_sym,
            :dest => destination(dest, d['tag'].to_sym),
          }
          Jekyll.logger.debug(@tag_name, "Adding dimension #{dimension}")
          dimensions.append(dimension)
        end

        distorted.dimensions = dimensions

        distorted.generate

        true
      end

    end  # Image
  end  # DistorteD
end  # Jekyll
