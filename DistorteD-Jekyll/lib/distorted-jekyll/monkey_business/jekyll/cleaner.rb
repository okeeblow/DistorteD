require 'set'

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
    # multiple destinations) with `files.merge(Set[*(item.destination(site.dest))])`
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
    end
  end  # Cleaner
end  # Jekyll
