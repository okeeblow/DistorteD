
require_relative 'ghost_revival/mr_mime' unless defined? ::CHECKING::YOU::MrMIME

module CHECKING::YOU::OUT::GHOST_REVIVAL

  # Path fragment for finding `shared-mime-info` package files.
  # This same subdir path applies when searching *any* `PATH` for `shared-mime-info` XML,
  # e.g. '/usr/share' + 'mime/packages' <-- this part
  # For consistency the same path is used for our local data under the Gem root.
  MIME_PACKAGES_FRAGMENT = proc { File.join(-'mime', -'packages') }

  # Filename for the main fdo `shared-mime-info` source XML.
  # We will look for this file in system `XDG_DATA_DIRS` and use our own bundled copy
  # if the system version is missing or outdated.
  FDO_MIMETYPES_FILENAME = -'freedesktop.org.xml'

  # Path to our built-in custom `shared-mime-info` database.
  DD_MIMETYPES_PATH = proc { File.join(
    ::CHECKING::YOU::OUT::GEM_ROOT.call,
    MIME_PACKAGES_FRAGMENT.call,
    -'distorted-types.xml',
  )}

  # Path to our bundled Apache Tika `shared-mime-info` database.
  TIKA_MIMETYPES_FILENAME = -'tika-mimetypes.xml'
  TIKA_MIMETYPES_PATH = proc { File.join(
    ::CHECKING::YOU::OUT::GEM_ROOT.call,
    -'third-party',
    -'tika-mimetypes',
    TIKA_MIMETYPES_FILENAME,
  )}

  # For now, unconditionally load all available files at startup.
  # TODO: Support partial on-the-fly loading à la `mini_mime`.
  def self.extended(otra)
    # Init a handler that will be passed to multiple instances of Ox::sax_parse()
    # for our multiple data files. I will just read them sequentially for now.
    handler = ::CHECKING::YOU::MrMIME.new

    # Load our own local database of custom types.
    handler.open(DD_MIMETYPES_PATH.call, strip_namespace: -'distorted')

    # Load the Apache Tika type database since it is not commonly installed like `shared-mime-info` is.
    handler.open(TIKA_MIMETYPES_PATH.call, strip_namespace: -'tika')

    # CYO bundles a copy of `freedesktop.org.xml` from `shared-mime-info` but will prefer a system-level copy
    # if one is available and not out of date. This flag will be disabled if we find a suitable copy,
    # otherwise our bundled copy will be loaded after we finish scanning the PATHs givin in our environment.
    load_bundled_fdo_xml = true

    # Search `XDG_DATA_DIRS` for any additional `shared-mime-info`-format data files we can load,
    # hopefully including the all-important `freedesktop.org.xml`.
    # T0DOs:
    # - Check if Homebrew sets this env var for its "/opt/homebrew/share" path
    #   or if I will have to include it manually with OS detection.
    # - Check if this code breaks on Winders where `PATH_SEPARATOR` is `;`
    #   and individual paths contain a drive letter and colon.
    # - Find a different data source on Windows?
    #   Not likely to even have `XDG` environment variables or `shared-mime-info` installed.
    # - Make it possible to specify additional paths directly to CYO.
    # - Make it possible to skip certain paths/files.
    ENV[-'XDG_DATA_DIRS'].split(File::PATH_SEPARATOR).map { |share_dir|

      # The environment variable will (should) contain directories at the `share` level of the `hier(7)`,
      # e.g. `/usr/share`, so we should append the known common fragment to that for a final path of
      # e.g. `/usr/share/mime/packages`!
      File.join(share_dir, MIME_PACKAGES_FRAGMENT.call)

    }.each { |mime_packages_dir|

      # Assume (for now) that every XML file in one of these paths will be something we want.
      Dir.glob('*.xml'.freeze, base: mime_packages_dir) { |xml_filename|

        # Get the absolute path to each candidate file.
        xml_path = File.join(mime_packages_dir, xml_filename)

        # Load the bundled `shared-mime-info` database if the system-level one exists but is out of date compared to our Gem.
        #
        # If the xml filename is `freedesktop.org.xml` aka `shared-mime-info`, compare its `mtime` to the build date
        # obtained from CYO's Gem::Specification. This will be a `Time` object but rounded down to midnight of the day it was built.
        # For development using a local tree that date will always be the current day.
        # NOTE: This assumes I will be timely about syncing upstream XML changes to my repo lol
        if File.basename(xml_path) == FDO_MIMETYPES_FILENAME
          if ::CHECKING::YOU::OUT::GEM_PACKAGE_TIME.call > File.mtime(xml_path)
            #puts "Skipping #{xml_path} because it is out of date (#{File.mtime(xml_path)}) compared to bundled copy (#{GEM_PACKAGE_TIME})"
          else
            load_bundled_fdo_xml = false
          end
        end
        handler.open(xml_path)
      }  # Dir::glob
    }  # ENV.each

    # If no suitable `shared-mime-info` was discovered in the environment, load our bundled copy.
    if load_bundled_fdo_xml
      handler.open(File.join(
        ::CHECKING::YOU::OUT::GEM_ROOT.call,
        -'third-party',
        -'shared-mime-info',
        "#{FDO_MIMETYPES_FILENAME}.in",
        # Yes I know why it's `.xml.in` but I'm doing it anyway 8)
      ))
    end

    # Detect UTF BOMs https://docs.microsoft.com/en-us/windows/win32/intl/using-byte-order-marks
    Array [
      String::new(str=-"\xEF\xBB\xBF", encoding: Encoding::ASCII_8BIT),      # UTF-8
      String::new(str=-"\xFF\xFE", encoding: Encoding::ASCII_8BIT),          # UTF-16LE
      String::new(str=-"\xFE\xFF", encoding: Encoding::ASCII_8BIT),          # UTF-16BE
      String::new(str=-"\xFF\xFE\x00\x00", encoding: Encoding::ASCII_8BIT),  # UTF-32LE
      String::new(str=-"\x00\x00\xFE\xFF", encoding: Encoding::ASCII_8BIT),  # UTF-32BE
    ].each_with_object(::CHECKING::YOU::OUT::from_ietf_media_type('text/plain')) { |sequence, textslashplain|
      textslashplain.add_content_match(::CHECKING::YOU::SweetSweet♥Magic::CatSequence::new.append(
        ::CHECKING::YOU::SweetSweet♥Magic::SequenceCat::new(sequence, (0...sequence.size), nil)  # `nil` `:mask`
      ))
    }
  end  # def self.extended
end  # module CHECKING::YOU::OUT::GHOST_REVIVAL
