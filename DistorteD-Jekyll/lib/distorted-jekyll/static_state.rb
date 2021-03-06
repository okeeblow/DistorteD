
require 'fileutils'
require 'set'

require 'distorted/error_code'


module Jekyll; end
module Jekyll::DistorteD; end

# This module implements the methods our tag needs in order to
# pretend to be a Jekyll::StaticFile so we don't need to
# redundantly re-implement a Generator and Jekyll::Cleaner.
module Jekyll::DistorteD::StaticState


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
    changes&.flat_map { |change| change.paths(dest_root) }
  end

  # HACK HACK HACK
  # Jekyll does not pass this method a site.dest like it does write() and
  # others, but I want to be able to short-circuit here if all the
  # to-be-generated files already exist.
  def modified?(dest_root = the_setting_sun(:jekyll, :destination).to_s)
    # Assume modified for the sake of freshness :)
    modified = true

    if Dir.exist?(dest_root)
      if Dir.exist?(File.join(dest_root, @relative_dest))
        extant_files = Dir.entries(File.join(dest_root, @relative_dest)).to_set

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
    return false unless modified?

    # Create any directories to the depth of the intended destination.
    FileUtils.mkdir_p(File.join(dest_root, @relative_dest))
    # Save every desired variation of this image.
    # This will be a Set of Hashes each describing the name, type,
    # dimensions, attributes, etc of each output variation we want.
    # Full-size outputs will have the special tag `:full`.
    changes&.each { |change|
      # Skip this Change if its files all already exist, to speed up site regeneration.
      # TODO: Make this configurable! I don't like that this can hide needed-regeneration
      #       due to e.g. changed Settings giving us a different output.
      #       Maybe hash the Atoms' values and use that in the filename as guarantee?
      next if change.paths(dest_root).map(&File.method(:file?)).all?

      if self.respond_to?(change.type.distorted_file_method)
        Jekyll.logger.debug("DistorteD::#{change.type.distorted_file_method}", change.name)
        # WISHLIST: Remove the empty final positional Hash argument once we require a Ruby version
        # that will not perform the implicit Change-to-Hash conversion due to Change's
        # implementation of :to_hash. Ruby 2.7 will complain but still do the conversion,
        # breaking downstream callers that want a Struct they can call arbitrary key methods on.
        # https://www.ruby-lang.org/en/news/2019/12/12/separation-of-positional-and-keyword-arguments-in-ruby-3-0/
        self.send(change.type.distorted_file_method, dest_root, change, **{})
      elsif extname == ".#{change.type.preferred_extension}"
        Jekyll.logger.debug(@name, <<~RAWCOPY
            No #{change.type.distorted_file_method} method is defined,
            but the intended output type #{change.type.to_s} is the same
            as the input type, so I will fall back to copying the raw file.
          RAWCOPY
        )
        copy_file(change.paths(dest_root).first)
      else
        Jekyll.logger.error(@name, "Missing write method #{change.type.distorted_file_method}")
        raise MediaTypeOutputNotImplementedError.new(change.path(dest_root), type_mars, self.class.name)
      end
    }
  end  # write

  # Returns source file path.
  # NOTE: Can't be private because Jekyll::Doctor as of version 4.2.0
  # will call this to show an obnoxious warning:
  # https://github.com/jekyll/jekyll/pull/8459
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


  private

  def copy_file(dest_path, *a, **k)
    if @site.safe || Jekyll.env == "production"
      FileUtils.cp(path, dest_path)
    else
      FileUtils.copy_entry(path, dest_path)
    end
  end  # copy_file

  # Basic file properties

  # Returns the extname /!\ including the dot /!\
  def extname
    File.extname(@name)
  end

  # Returns last modification time for this file.
  def mtime
    (@modified_time ||= File.stat(path).mtime).to_i
  end

  # Returns a Set of just the String filenames we want for this media.
  # This will be used by `modified?` among others.
  def wanted_files
    # Cooltrainer::Change#names returns an Array[String], so we must concat every Change into one.
    changes.map(&:names).reduce(&:concat).to_set
  end


end
