require 'set'
require 'distorted-jekyll/media_molecule'

module Jekyll
  # Handles the cleanup of a site's destination before it is built or re-built.
  class Cleaner

    # Private: The list of files to be created when site is built.
    #
    # Returns a Set with the file paths
    #
    # Monkey-patch this to look for DD's unique `destinations` which is similar
    # to the original `destination` method except it returns a Set of destination
    # paths instead of a single destination path.
    # Do the patch with `define_method` instead of just `def` because the block's
    # closure of the local scope lets it carry a binding to the original overriden
    # method which I use to bail out iff the monkey-patch fails.
    # This is an attempt to avoid breaking future Jekyll versions as much as
    # possible, since any Exception in the monkey-patched code will just cause
    # the original Jekyll implementation to be called instead.
    # The new worst case scenario is slow site builds due to media variation generation!
    #
    # If a StaticFile responds to `destinations` then use it and merge the result.
    # I'm defining my own separate method for multi-destinations for now,
    # but I also considered just overriding `destination` to return the Set and
    # then doing this as a one-liner that handles either case (single or
    # multiple destinations) with `files.merge(Set[*(item.destination(site.dest))])`.
    # This is the safer choice though since we avoid changing the outout type of the
    # regular `:destination` method.
    the_old_new_thing = instance_method(:new_files)
    define_method(:new_files) do
      begin
        @new_files ||= Set.new.tap do |files|
          site.each_site_file { |item|
            if item.respond_to?(:destinations)
              files.merge(item.destinations(site.dest))
            elsif item.respond_to?(:destination)
              files << item.destination(site.dest)
            else
              # Something unrelated has gone wrong for us to end up sending
              # `destination` to something that doesn't respond to it.
              # We should fall back to the original implementation of `new_files`
              # in this case so the failure doesn't appear to be here.
              the_old_new_thing.bind(self).()
            end
          }
        end
      rescue RuntimeError => e
        Jekyll.logger.warn('DistorteD', "Monkey-patching Jekyll::Cleaner#new_files failed: #{e.message}")
        Jekyll.logger.debug('DistorteD', "Monkey-patched Jekyll::Cleaner#new_files backtrace: #{e.backtrace}")
        the_old_new_thing.bind(self).()
      end
    end  # define_method :new_files


    # Private: Creates a regular expression from the config's keep_files array
    #
    # Examples
    #   ['.git','.svn'] with site.dest "/myblog/_site" creates
    #   the following regex: /\A\/myblog\/_site\/(\.git|\/.svn)/
    #
    # Returns the regular expression
    #
    # Monkey-patch this to protect DistorteD-generated files from destruction
    # https://jekyllrb.com/docs/configuration/incremental-regeneration/
    # when running Jekyll in Incremental mode twice in a row.
    #
    # The first Incremental build will process our Liquid tags on every post/page
    # which will add our generated files to Jekyll::Cleaner's :new_files (See above!)
    # A second build, however, will not re-process any posts/pages that haven't changed.
    # Our Tags never get initialized, so their previously-generated files now appear
    # to be spurious and will get purged.
    #
    # Work around this by merging Jekyll::Cleaner#keep_file_regex with a second Regexp
    # based on the :preferred_extension for every MIME::Type DistorteD can output.
    mr_regular = instance_method(:keep_file_regex)
    define_method(:keep_file_regex) do
      begin
        # We're going to use it either way, so go ahead and get what the :keep_file_regex
        # would have been in unpatched Jekyll, e.g.:
        # (?-mix:\A/home/okeeblow/Works/cooltrainer/_site\/(\.git|\.svn))
        super_regexp = mr_regular.bind(self).()

        # If we aren't in Incremental mode then each Tag will explicitly declare
        # the files they write, and that's preferrable to this shotgun approach
        # since the Regexp approach may preserve unwanted files, but "Some unwanted files"
        # is way nicer than "fifteen minutes rebuilding everything" rofl
        if site&.incremental?
          # Discover every supported output MIME::Type based on every loaded MediaMolecule.
          outer_limits = Cooltrainer::DistorteD::IMPLANTATION(
            :OUTER_LIMITS,
            Cooltrainer::DistorteD::media_molecules,
          ).values.flat_map(&:keys)

          # Build a new Regexp globbing the preferred extension of every Type we support, e.g.:
          # (?-mix:\A/home/okeeblow/Works/cooltrainer/_site/.*(txt|nfo|v|ppm|pgm|pbm|hdr|png|jpg|webp|tiff|fits|gif|bmp|ttf|svg|pdf|mpd|m3u8|mp4))
          #
          # Some Types may have duplicate preferred_extensions, and some might have nil
          # (e.g. our own application/x.distorted.never-let-you-down), so :uniq and :compact them out.
          outer_regexp = %r!\A#{Regexp.quote(site.dest)}/.*(#{Regexp.union(outer_limits&.map(&:preferred_extension).uniq.compact).source})!

          # Do the thing.
          combined_regexp = Regexp.union(outer_regexp, super_regexp)
          Jekyll.logger.debug(
            'Protecting DistorteD-generated files from Incremental-mode destruction with new Jekyll::Cleaner#keep_file_regex',
            combined_regexp.source)
          return combined_regexp
        else
          # Feels like I'm patching nothin' at all… nothin' at all… nothin' at all!
          return super_regexp
        end
      rescue RuntimeError => e
        Jekyll.logger.warn('DistorteD', "Monkey-patching Jekyll::Cleaner#keep_file_regex failed: #{e.message}")
        Jekyll.logger.debug('DistorteD', "Monkey-patched Jekyll::Cleaner#keep_file_regex backtrace: #{e.backtrace}")
        # Bail out by returning what the :keep_file_regex would have been without this patch.
        mr_regular.bind(self).()
      end
    end  # define_method :keep_file_regex

  end  # Cleaner
end  # Jekyll
