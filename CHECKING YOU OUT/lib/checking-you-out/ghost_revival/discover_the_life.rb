require(-'pathname') unless defined?(::Pathname)


# Methods for finding all appropriate source data files in the running environment.
module ::CHECKING::YOU::IN::GHOST_REVIVAL

  # Filename for the main fdo `shared-mime-info` source XML.
  # We will look for this file in system `XDG_DATA_DIRS` and use our own bundled copy
  # if the system version is missing or outdated.
  FDO_MIMETYPES_FILENAME = -'freedesktop.org.xml'

  # Custom `Pathname` subclass to describe our `shared-mime-info` XML packages' paths,
  # allowing a `Ractor` type pool to easily differentiate those messages from messages
  # seeking the `CHECKING::YOU::OUT` type for an extant or arbitrary `Pathname`.
  SharedMIMEinfo = ::Class.new(::Pathname)


  # Identify all `shared-mime-info`-format source XML packages available in the current environment.
  # - Searches the `XDG_DATA_HOME`/`XDG_DATA_DIRS` environment variables common on BSD/Lunix systems.
  #   This is the recommended way to discover `shared-mime-info` packages per the manual:
  #   https://specifications.freedesktop.org/shared-mime-info-spec/latest/ar01s02.html#s2_layout
  # - Includes the path to `CHECKING::YOU::OUT`'s bundled `shared-mime-info` iff it is newer than an installed copy.
  def discover_fdo_xml
    # CYO bundles a copy of `freedesktop.org.xml` from `shared-mime-info` but will prefer a system-level copy
    # if one is available and not out of date. This flag will be disabled if we find a suitable copy,
    # otherwise our bundled copy will be loaded after we finish scanning the PATHs givin in our environment.
    load_bundled_fdo_xml = true

    # Search `XDG_DATA_DIRS` for any additional `shared-mime-info`-format data files we can load,
    # hopefully including the all-important `freedesktop.org.xml`.
    ::CHECKING::YOU::OUT::XROSS_INFECTION::XDG.DATA.push(
      # Append out Gem-local path to the very end (lowest priority)
      ::CHECKING::YOU::OUT::GEM_ROOT.call
    ).map {
      # Add path fragments for finding `shared-mime-info` package files.
      # This same subdir path applies when searching *any* `PATH` for `shared-mime-info` XML,
      # e.g. '/usr/share' + 'mime/packages' <-- this part
      # For consistency the same path is used for our local data under the Gem root.
      _1.join(-'mime', -'packages')
    }.flat_map {
      # Find all XML files under all subdirectories of all given `Pathname`s.
      #
      # `#glob` follows the same conventions as `File::fnmatch?`:
      # https://ruby-doc.org/core-3.0.2/File.html#method-c-fnmatch
      #
      # `EXTGLOB` enables the brace-delimited glob syntax, used here to allow an optional `'.in'` extname
      # as found on the `'freedesktop.org.xml.in'` bundled with our Gem since I don't want to rename
      # the file from the XDG repo even though that extname means they don't want us to use that file directly.
      _1.glob(File.join(-'**', -'*.xml{.in,}'), ::File::FNM_EXTGLOB)
    }.each_with_object(::CHECKING::YOU::OUT::GEM_ROOT.call).with_object(Array.new) { |(xml_path, gem_root), out|

      # Load the bundled `shared-mime-info` database if the system-level one exists but is out of date
      # compared to our Gem. Using `String#include?` here since the system-level file will be
      # `'freedesktop.org.xml'` but the bundled copy will be `'freedesktop.org.xml.in'`.
      if xml_path.basename.to_s.include?(FDO_MIMETYPES_FILENAME)
        # `Pathname#ascend` returns an `Enumerator` of `Pathname`s up one level at a time until reaching fs root.
        # If *any* of these are equal to `GEM_ROOT` then we have found the bundled copy, otherwise system copy.
        if (xml_path.ascend { break true if _1 ==  gem_root} || false) then
          # Found bundled copy.
          # A new-enough system-level copy will disable this flag to prevent loading outdated bundled data.
          next unless load_bundled_fdo_xml
        else
          # Found system-level copy.
          # Use this if it's newer than our Gem, and set a flag to prevent loading the bundled copy if so.
          next if ::CHECKING::YOU::OUT::GEM_PACKAGE_TIME.call > xml_path.mtime
          load_bundled_fdo_xml = false
        end
      end

      out.push(xml_path)

    }.map!(&SharedMIMEinfo::method(:new))  # Wrap everything into our custom `Pathname` subclass for easy identification.

  end  # def discover_fdo_xml

end
