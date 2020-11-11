
require 'fileutils'
require 'set'

require 'distorted/error_code'


module Jekyll; end
module Jekyll::DistorteD; end

# This module implements the methods our tag needs in order to
# pretend to be a Jekyll::StaticFile so we don't need to
# redundantly re-implement a Generator and Jekyll::Cleaner.
module Jekyll::DistorteD::StaticState


  ATTRIBUTES = Set[:title]


  # Returns the to-be-written path of a single standard StaticFile.
  # The value returned by this method is only the 'main' or 'original'
  # (even if modified somehow) file and does not include the
  # path/filenames of any variations.
  # This method will be called by jekyll/lib/cleaner#new_files
  # to generate the list of files that need to be build or rebuilt
  # for a site. For this reason, this method shouldn't do any kind
  # of checking the real filesystem, since e.g. its URL-based
  # destdir might not exist yet if the Site.dest is completely blank.
  def destination(dest_root)
    File.join(dest_root, @relative_dest, @name)
  end

  # This method will be called by our monkey-patched Jekyll::Cleaner#new_files
  # in place of the single-destination method usually used.
  # This allows us to tell Jekyll about more than a single file
  # that should be kept when regenerating the site.
  # This makes DistorteD fast!
  def destinations(dest_root)
    wanted_files.map{|f| File.join(dest_root, @relative_dest, f)}
  end

  # HACK HACK HACK
  # Jekyll does not pass this method a site.dest like it does write() and
  # others, but I want to be able to short-circuit here if all the
  # to-be-generated files already exist.
  def modified?
    # Assume modified for the sake of freshness :)
    modified = true

    site_dest = Jekyll::DistorteD::Setting::config(:destination).to_s
    if Dir.exist?(site_dest)
      if Dir.exist?(File.join(site_dest, @relative_dest))
        extant_files = Dir.entries(File.join(site_dest, @relative_dest)).to_set

        # TODO: Make this smarter. It's not enough that all the generated
        # filenames should exist. Try a few more ways to detect subtler
        # "changes to the source file since generation of variations.
        if wanted_files.subset?(extant_files)
          Jekyll.logger.debug(@name, "All variations present: #{wanted_files}")
          modified = false
        else
          Jekyll.logger.debug(@name, "Missing variations: #{wanted_files - extant_files}")
        end

      end  # relative_dest.exists?
    end  # site_dest.exists?
    Jekyll.logger.debug("#{@name} modified?",  modified)
    return modified
  end  # modified?

  # Whether to write the file to the filesystem
  #
  # Returns true unless the defaults for the destination path from
  # _config.yml contain `published: false`.
  def write?
    publishable = defaults.fetch('published'.freeze, true)
    return publishable unless @collection

    publishable && @collection.write?
  end

  # Write the static file to the destination directory (if modified).
  #
  # dest - The String path to the destination dir.
  #
  # Returns false if the file was not modified since last time (no-op).
  def write(dest_root)
    plug
    return false if File.exist?(path) && !modified?

    # Create any directories to the depth of the intended destination.
    FileUtils.mkdir_p(File.join(dest_root, @relative_dest))
    # Save every desired variation of this image.
    # This will be a Set of Hashes each describing the name, type,
    # dimensions, attributes, etc of each output variation we want.
    # Full-size outputs will have the special tag `:full`.
    files.each { |variation|
      type = variation&.dig(:type)
      filename = File.join(dest_root, @relative_dest, variation&.dig(:name) || @name)

      if self.respond_to?(type.distorted_method)
        Jekyll.logger.debug("DistorteD::#{type.distorted_method}", filename)
        self.send(type.distorted_method, filename, **variation)
      elsif extname == ".#{type.preferred_extension}"
        Jekyll.logger.debug(@name, <<~RAWCOPY
            No #{type.distorted_method} method is defined,
            but the intended output type #{type.to_s} is the same
            as the input type, so I will fall back to copying the raw file.
          RAWCOPY
        )
        copy_file(filename)
      else
        Jekyll.logger.error(@name, "Missing rendering method #{type.distorted_method}")
        raise MediaTypeOutputNotImplementedError.new(filename, type, self.class.name)
      end
    }
  end  # write

  private

  def copy_file(dest_path, *a, **k)
    if @site.safe || Jekyll.env == "production"
      FileUtils.cp(path, dest_path)
    else
      FileUtils.copy_entry(path, dest_path)
    end
  end  # copy_file

  # Basic file properties

  # Filename without the dot-and-extension.
  def basename
    File.basename(@name, '.*')
  end

  # Returns the extname /!\ including the dot /!\
  def extname
    File.extname(@name)
  end

  # Returns last modification time for this file.
  def mtime
    (@modified_time ||= File.stat(path).mtime).to_i
  end

  # Returns source file path.
  def path
    @path ||= begin
      # Static file is from a collection inside custom collections directory
      if !@collection.nil? && !@site.config['collections_dir'.freeze].empty?
        File.join(*[@base, @site.config['collections_dir'.freeze], @dir, @name].compact)
      else
        File.join(*[@base, @dir, @name].compact)
      end
    end
  end

  # Returns a Hash keyed by MIME::Type objects with value as a Set of Hashes
  # describing the media's output variations to be generated for each Type.
  def variations
    changes(abstract(:changes)).map{ |t|
      [t, outer_limits(abstract(:outer_limits)).map{ |d|

        # Don't change the filename of full-size variations
        tag = d&.dig(:tag) != :full ? '-'.concat(d&.dig(:tag).to_s) : ''.freeze
        # Use the original extname for LastResort
        ext = t == CHECKING::YOU::OUT('application/x.distorted.last-resort') ? File.extname(@name) : t.preferred_extension
        # Handle LastResort for files that might be a bare name with no extension
        dot = '.'.freeze unless ext.nil? || ext&.empty?

        d.merge({
          # e.g. 'SomeImage-medium.jpg` but just `SomeImage.jpg` and not `SomeImage-full.jpg`
          # for the full-resolution outputs.
          # The default `.jpeg` preferred_extension is monkey-patched to `.jpg` because lol
          :name => "#{basename}#{tag}#{dot}#{ext}",
        })

      }]
    }.to_h
  end

  # Returns a flat Set of Hashes that each describe one variant of
  # media file output that should exist for a given input file.
  def files
    filez = Set[]
    variations.each_pair{ |t,v|
      # Merge the type in to each variation Hash since we will no longer
      # have it as the key to this Set in its container Hash.
      v.each{ |d| filez.add(d.merge({:type => t})) }
    }
    filez
  end

  # Returns a Set of just the String filenames we want for this media.
  # This will be used by `modified?` among others.
  def wanted_files
    files.map{|f| f[:name]}.to_set
  end


end
