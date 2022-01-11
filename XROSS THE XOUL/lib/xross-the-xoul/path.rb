require(-'pathname') unless defined?(::Pathname)

require_relative(-'os') unless defined?(::XROSS::THE::OS)


# Components for cross-Desktop `::Pathname` resolution, e.g. directories for configuration, data, cache, etc.
#
# Our implementation of the XDG specifications are for Unix-like OSes.
# Windows and macOS do their own thing, and the Mac is especially complicated here.
#
# See the details at the bottom of this file.
class XROSS; end
class XROSS::THE; end
class XROSS::THE::PATH

  # TODO: Eliminate this once `::ENV` is shareable on its own: https://bugs.ruby-lang.org/issues/17676
  self::DD_ENV = ::Ractor::make_shareable(::Hash::new.merge(::ENV))

  # Generic method to return absolute `Pathname`s for the contents of a given environment variable.
  #
  # Per https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html —
  # "All paths set in these environment variables must be absolute. If an implementation encounters
  #  a relative path in any of these variables it should consider the path invalid and ignore it."
  # I don't really like this, but we should match the behavior of XDG by default anyway.
  #
  # I'm also going to `#expand_path` for the "_HOME" XDG variables (e.g. `$XDG_DATA_HOME`, `$XDG_BIN_HOME`, etc)
  # since they're likely to be defined with a relative reference to the homedir path.
  #
  # Note the difference in behavior between "home" as a shell expansion (the tilde / `~`), vs as an exported
  # variable (`$HOME`) interpreted by our shell, vs as a variable name passed in as a raw `::String`:
  #
  #   [okeeblow@emi#CHECKING YOU OUT] TESTVAR=$HOME/hello.jpg ruby -e "p ENV['TESTVAR']"
  #   "/home/okeeblow/hello.jpg"
  #   [okeeblow@emi#CHECKING YOU OUT] TESTVAR="$HOME/hello.jpg" ruby -e "p ENV['TESTVAR']"
  #   "/home/okeeblow/hello.jpg"
  #   [okeeblow@emi#CHECKING YOU OUT] TESTVAR='$HOME/hello.jpg' ruby -e "p ENV['TESTVAR']"
  #   "$HOME/hello.jpg"
  #   [okeeblow@emi#CHECKING YOU OUT] TESTVAR='$HOME/hello.jpg' ruby -r 'optionparser' -e "p OptionParser::new.environment('TESTVAR')"
  #   ["$HOME/hello.jpg"]
  #   [okeeblow@emi#CHECKING YOU OUT] TESTVAR='~/hello.jpg' ruby -e "p ENV['TESTVAR']"
  #   "~/hello.jpg"
  #   [okeeblow@emi#CHECKING YOU OUT] TESTVAR='~okeeblow/hello.jpg' ruby -e "p ENV['TESTVAR']"
  #   "~okeeblow/hello.jpg"
  #   [okeeblow@emi#CHECKING YOU OUT] TESTVAR='~/hello.jpg' ruby -r 'pathname' -e "p ::Pathname::new(ENV['TESTVAR']).expand_path"
  #   #<Pathname:/home/okeeblow/hello.jpg>
  #   [okeeblow@emi#CHECKING YOU OUT] TESTVAR='~okeeblow/hello.jpg' ruby -r 'pathname' -e "p ::Pathname::new(ENV['TESTVAR']).expand_path"
  #   #<Pathname:/home/okeeblow/hello.jpg>
  #   [okeeblow@emi#CHECKING YOU OUT] TESTVAR='$HOME/hello.jpg' ruby -r 'pathname' -e "p ::Pathname::new(ENV['TESTVAR']).expand_path"
  #   #<Pathname:/home/okeeblow/Works/DistorteD/CHECKING YOU OUT/$HOME/hello.jpg>
  #
  # I'm not going to attempt to interpret raw variable-name `::String`s (like `'$HOME'`) for now.
  def self.ENVIRONMENTAL_PATHNAMES(variable, allow_relative = false)
    # Skip empty-`String` variables as well as missing variables.
    # Helper methods should provide appropriate defaults when we fail this condition and return `nil`.
    if self::DD_ENV.has_key?(variable) and not self::DD_ENV[variable]&.empty?
      # `PATH_SEPARATOR` will be a colon (:) on UNIX-like systems and semi-colon (;) on Windows.
      # Convert path variable contents to `Pathname`s with…
      # - :expand_path  —  Does shell expansion of path `String`s, e.g. `File.expand_path('~') == Dir::home`
      # - :directory?   —  Drop any expanded `Pathname`s that don't refer to extant directories.
      # - :realpath     —  Follow symbolic links and expand dots (`.` and `..`) if `#expand_path` didn't already.
      #                    Raises `Errno::ENOENT` for nonexistent paths, so `#keep_if(&:directory)` must come first.
      self::DD_ENV[variable]
        .split(::File::PATH_SEPARATOR)
        .map!(&::Pathname::method(:new))
        .send((allow_relative or variable.end_with?(-'_HOME') ? :map! : :itself), &:expand_path)
        .keep_if(&:directory?)
        .map!(&:realpath)
    end
  end

  # "`$XDG_DATA_DIRS` defines the preference-ordered set of base directories to
  # search for data files in addition to the `$XDG_DATA_HOME` base directory."
  def self.DATA_DIRS
    # "If `$XDG_DATA_DIRS` is either not set or empty,
    # a value equal to `/usr/local/share/:/usr/share/` should be used."
    self.ENVIRONMENTAL_PATHNAMES(-'XDG_DATA_DIRS') || ['/usr/local/share/', '/usr/share/'].tap {
      # Fixup platforms where we know to expect filez outside the fd.o defaults.
      # Specific documentation references:
      # - https://docs.brew.sh/Installation
      if ::XROSS::THE::OS::mac? then
        _1.append('/opt/homebrew/share/')  # Homebrew on ARM
        _1.append('/usr/local/share/')     # Homebrew on Intel / Tigerbrew on PPC
        _1.append('/opt/local/share/')     # MacPorts
      end
    }.map(&::Pathname::method(:new)).keep_if(&:directory?).map(&:realpath)
  end  # DATA_DIRS

  # "`$XDG_DATA_HOME` defines the base directory relative to which user-specific data files should be stored."
  def self.DATA_HOME
    self.ENVIRONMENTAL_PATHNAMES(-'XDG_DATA_HOME') || [
      # "If `$XDG_DATA_HOME` is either not set or empty, a default equal to $HOME/.local/share should be used."
      ::Pathname.new(::Dir::home).expand_path.realpath.join(-'.local', -'share')
    ]
  end

  # "`$XDG_CONFIG_HOME` defines the base directory relative to which user-specific configuration files should be stored."
  def self.CONFIG_HOME
    self.ENVIRONMENTAL_PATHNAMES(-'XDG_CONFIG_HOME') || [
      # "If `$XDG_CONFIG_HOME` is either not set or empty, a default equal to `$HOME/.config` should be used."
      ::Pathname.new(::Dir::home).expand_path.realpath.join(-'.config')
    ]
  end

  # "`$XDG_STATE_HOME` defines the base directory relative to which user-specific state files should be stored."
  def self.STATE_HOME
    self.ENVIRONMENTAL_PATHNAMES(-'XDG_STATE_HOME') || [
      # "If `$XDG_STATE_HOME` is either not set or empty, a default equal to `$HOME/.local/state` should be used. "
      ::Pathname.new(::Dir::home).expand_path.realpath.join(-'.local', -'state')
    ]
  end

  # `$XDG_BIN_HOME` isn't in the `basedir` specification (version 0.8 at the time of this writing),
  # but it is in semi-common use and has been a proposed patch for some years:
  # - https://gitlab.freedesktop.org/xdg/xdg-specs/-/issues/14
  # - https://gitlab.freedesktop.org/xdg/xdg-specs/-/issues/63
  # - https://lists.freedesktop.org/archives/xdg/2017-August/013943.html
  def self.BIN_HOME
    self.ENVIRONMENTAL_PATHNAMES(-'XDG_BIN_HOME') || [
      # The current specification *does* name the actual path, just not the `$XDG_BIN_HOME` variable for it:
      # "User-specific executable files may be stored in `$HOME/.local/bin`.
      #  Distributions should ensure this directory shows up in the UNIX `$PATH` environment variable,
      #  at an appropriate place."
      # "Since `$HOME` might be shared between systems of different achitectures, installing compiled binaries
      #  to `$HOME/.local/bin` could cause problems when used on systems of differing architectures."
      ::Pathname.new(::Dir::home).expand_path.realpath.join(-'.local', -'bin')
    ]
  end

  # Returns a combined `Array` of user-specific and system-wide XDG Data `Pathname`s.
  def self.DATA
    # The base directory defined by `$XDG_DATA_HOME` is considered more important
    # than any of the base directories defined by `$XDG_DATA_DIRS`.
    self.DATA_DIRS + self.DATA_HOME
  end

  # Hide the `Pathname`-making helper method.
  private_class_method(:ENVIRONMENTAL_PATHNAMES)

end

# Background information on the behavior of various systems and how they got that way.
#
#
#
### Lunix/BSD/HURD/Redox/etc
#
# On Unix-like platforms we should follow the freedesktop-dot-org (originally XDG, for "Cross Desktop Group")
# `basedir` and `xdg-user-dirs` specifications:
# - https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
# - https://www.freedesktop.org/wiki/Software/xdg-user-dirs/
#
# More info/history:
# - https://www.freedesktop.org/wiki/Specifications/
# - https://specifications.freedesktop.org/
# - https://gitlab.freedesktop.org/xdg/xdg-specs
# - https://lwn.net/2000/0427/a/freedesktop.html
# - https://wiki.archlinux.org/title/XDG_Base_Directory
#
# The reference XDG `basedir` implementation seems to be spread among a few freedesktop-dot-org
# sub-projects like `xdg-utils`. See here for example:
# - https://gitlab.freedesktop.org/xdg/xdg-utils/-/blob/master/scripts/xdg-utils-common.in
# - `search="${XDG_DATA_HOME:-$HOME/.local/share}:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"`
#
#
### Winders
#
# # Win32s – Windows XP
#
# "Constant special ID list" (CSIDL) hexadecimal values depend on the version of the shell DLL,
# presence/absence of MSIE, etc.
# - https://docs.microsoft.com/en-us/windows/win32/shell/csidl
# - https://tarma.com/support/im9/using/symbols/functions/csidls.htm
# - https://www.pinvoke.net/default.aspx/shell32/CSIDL.html
# - https://perldoc.perl.org/Win32.txt
#
# # Windows Vista – present day; present time
#
# "Known Folders" GUID constants are available since Windows Vista and are intended as the replacement for CSIDL.
# - https://docs.microsoft.com/en-us/windows/win32/shell/known-folders
# - https://docs.microsoft.com/en-us/windows/win32/shell/knownfolderid
#
# # Other toolkits' behavior on Windows
#
# Refer to Qt's `QStandardPath`: https://doc.qt.io/qt-6/qstandardpaths.html#StandardLocation-enum
#
# KDE4 on Windows seems to have used `%PROGRAMDATA%\KDE\share\` as `$XDG_DATA_DIRS`,
# but I'm going to ignore it since there's no Plasma 5 for Windows and Qt now provides `QStandardPath`.
#
#
#
### macOS (née Mac OS X, née Rhapsody, née OPENSTEP, née NeXTSTEP — capitalize those as you see fit)
#
# Apple's `Foundation Kit` Framework in macOS has gone through a few generational revisions,
# but the overall concept remains the same since around the time of Mac OS X 10.0.
# It's also helpful to look at the ancestor systems to see how they arrived at the solution they did.
#
#
# # Macintosh 64KiB ROM (Macintosh 128K, Macintosh XL, and Macintosh 512K non-Ke)
#
# In The Beginning there was MFS, the Macintosh File System.
# There was no filesystem hierarchy, so directories were mostly cosmetic.
# Files had a data fork, and a resource fork.
# File names were limited to 255 characters and were encoded in what we know today
# as the "MacRoman" character set (or, later, one of the regional variants like "MacJapanese").
#
# The high-level functions for opening data forks and resource forks were `FSOpen` and `PBOpenRF`,
# respectively. They took a file name and a volume identifier, and they returned a file reference number.
# This was back in the days of 400K 3.5" disks, so disk swapping was common and a file reference
# to an unmounted volume would prompt the user to insert that disk.
#
# The low-level equivalents used by `FSOpen` and `OpenRF` were `PBOpen` and `PBOpenRF`, respectively.
# I'm not going to go into all the details of file access for an old computer here since this `::Module`
# is only about identifying paths, but it's important to have the historical context.
#
# PB == "Parameter Block" in this context. Inside Macintosh sez:
# "There are three different kinds of parameter blocks you'll pass to File Manager routines.
#  Each kind is used with a particular set of routine calls: I/O routines, file information routines,
#  and volume information routines."
#
# This was first documented in Volume Ⅱ Chapter 4 of the original Inside Macintosh series.
# https://vintageapple.org/inside_o/pdf/Inside_Macintosh_Volume_II_1985.pdf#page=86
#
#
# # HD20 `INIT` and Macintosh 128KiB ROM (Macintosh 512Ke and MACプラス)
#
# Here's where the Macintosh starts looking a lot more modern. These systems support HFS and 800K disks.
# As the "H" in HFS implies, directories were now a real thing and could be nested.
#
# See Volume Ⅳ Chapter 19 of the original Inside Macintosh series:
# https://vintageapple.org/inside_o/pdf/Inside_Macintosh_Volume_IV_1986.pdf#page=97
#
# Directory names could be 31 characters, and volume names could be 27.
# File names were also limited to 31 characters with the Hierarchical File Manager,
# a change from the 255 characters allowed originally.
# This was due to certain underlying 255-character String limits.
#
# Per Inside Macintosh:
# "The 64K ROM version of the File Manager allows file names of up to 255 characters.
#  File names should be constrained to 31 characters, however, to maintain compatibility with
#  the 128K ROM version of the File Manager."
#
# The updated functions for opening a data/resource fork now take a directory identifier
# in addition to the file name and volume identifier. Older applications using the older functions
# could still work on HFS since they would get the "working directory" set via `OpenWD`.
#
# HFS was the introduction of the colon path separator:
# "The 128K ROM version of the File Manager also permits the specification of files (and directories)
#  using concatenations of volume names, directory names, and file names. Separated by colons,
#  these concatenations of names are known as pathnames. A full pathname always begins with the name
#  of the root directory; it names the path from the root to a given file or directory,
#  and includes each of the directories visited on that path."
# Note that the "root directory" name here is the name of the Volume.
#
# Note how there's still very little discussion of finding special folder paths
# (you know, the thing this wall-of-text comment is actually about) since the System Resources File
# used to have to be modified directly and the Finder was identified by a unique Type/Creator Code pair.
# However you can see the beginning of this with support for external INITs.
# Per Inside Macintosh:
# "A special initialization resource in the system resource file, `INIT` resource 31,
#  searches the System Folder of the system startup volume for files of type `INIT` or `RDEV`."
#
# A/UX 2.0's virtual Toolbox is the exception to the lower file name length limit and allows
# 255-character file names with the change to UFS from the SysV filesystem used in A/UX 1.0:
# http://bitsavers.org/pdf/apple/mac/a_ux/aux_2.0/030-0787-A_AUX_Toolbox_Macintosh_ROM_Interface_1990.pdf#page=90
# "The maximum HFS name is 32 characters, and longer names brought into the Macintosh as environment are truncated."
#
#
# # Macintosh 256KiB ROM (Macintosh SE and Macintosh Ⅱ)
#
# These File Manager additions were AppleTalk-focused and are not super relevant to this `::Module`,
# at least not directly. It would influence the subsequent System 7:
# https://vintageapple.org/inside_o/pdf/Inside_Macintosh_Volume_V_1986.pdf#page=380
#
#
# # Macintosh System 7
#
# The System Folder now has separate Control Panel, Extensions, Preferences, etc directories!
# Per Inside Macintosh Volume Ⅵ Chapter 9, "The System Folder and its Related Directories" section:
# https://vintageapple.org/inside_o/pdf/Inside_Macintosh_Volume_VI_1991.pdf#page=604
#
# "In version 7.0, the System Folder contains a set of folders for storing related files.
#  If your application needs to store a file in the System Folder, put it in one of the new directories
#  described in this chapter. The Toolbox provides a new function, `FindFolder`,
#  to help your application utilize this new organization."
#
# "Your application passes the `FindFolder` function a target volume and a constant that tells it
#  which directory you're interested in. `FindFolder` returns a volume reference number and a directory ID.
#  If the specified directory does not exist, `FindFolder` can create it and return the new directory ID.
#  Don't assume files are on the same volume as your application;
#  they could be on a different local volume or on a remote volume on a network."
#
# I'm not going to reproduce the full list here, but you can see them on Chapter 9 Page 43:
# https://vintageapple.org/inside_o/pdf/Inside_Macintosh_Volume_VI_1991.pdf#page=608
#
# All-lowercase Resource-name values for these constants (e.g. `amnu` for `kAppleMenuFolderType`)
# are "reserved", as indicated in May 1985's Macintosh Technical Note #32:
# https://vintagecomputer.ca/files/Apple/Macintosh/developer/MacSupplement-May.1985.pdf#page=87
#
# It's also worth noting that System 7 introduced the `FSSpec` structure for representing handles to paths.
# See the "File Manager" Chapter 25:
# https://vintageapple.org/inside_o/pdf/Inside_Macintosh_Volume_VI_1991.pdf#page=1265
#
# "The FSSpec record described in the […] section, 'File System Specifications,' replaces both the MFS
#  and the HFS conventions for identifying files and directories in most cases. In system software version 7.0,
#  you use the historical forms primarily when calling low-level File Manager functions."
#
# System 7 also introduced the Alias Manager, and aliases resolve into `FSSpec`s.
#
#
# # Mac OS 8
#
# Lots of new default FolderType constants were added:
# https://web.archive.org/web/20010718060843/http://developer.apple.com/techpubs/macos8/Files/FolderManager/FolderMgrRef/FolderMgrRef.d.html
#
# Developers could register new FolderTypes. See the "Folder Manager" section of Technical Note 1102:
# - https://web.archive.org/web/20100622024821/http://developer.apple.com/legacy/mac/library/technotes/tn/tn1102.html#foldermanager
# - http://mirror.informatimago.com/next/developer.apple.com/technotes/tn/tn1102.html#foldermanager
#
#
# # NeXTSTEP 2.x
#
# Let's not forget the other parent of Mac OS X :)
#
# The early NeXT systems booted UFS Magneto-Optical disks, accessed other machines via NFS,
# and used a more "traditional" Unix-like directory hierarchy, environment variables, etc.
#
# For example, see this 1990 Developer Tools document describing the `$PATH` environment variable:
# http://www.bitsavers.org/pdf/next/Release_1_Dec90/Development_Tools_Dec90.pdf#page=40 —
#
#   "You can start an application on a NeXT computer in several ways. When you start an application
#    by typing its name in the shell, or by opening a document file from the File Viewer,
#    the Workspace Manager has to find the executable file for that application.
#    It looks for the executable file in a systematic sequence of directory paths,
#    beginning with the current directory. This search sequence is contained in an environmental variable `path`.
#    Because of this search sequence, you can replace an application located later in the sequence
#    with one of the same name earlier in the sequence.
#
#    For example, `$(HOME)/Apps` occurs before `/NextApps` in `path`; if you place an application
#    in the directory `$(HOME)/Apps` with the same name as an application in the `/NextApps` directory,
#    the Workspace Manager finds and starts the version in `$(HOME)/Apps`.
#    You should consider the path when naming and installing applications."
#
# Or as shown in "NeXTSTEP Programming: STEP ONE: Object-Oriented Applications" (1992)
# by Simson L. Garfinkel and Michael K. Mahoney:
# https://simson.net/ref/1993/NeXTSTEP3.0.pdf#page=6 —
#
#   "Below we list the directories and files that you need for changing
#    the NeXTSTEP 2.1 Standard Edition into something you can program with."
#
#   ```
#     Directories:
#       /lib, /usr/lib/nib, /usr/include
#
#     Files (programs) in /bin:
#       ar      file
#       ld      segedit
#       as      g++filt
#       nm      size
#       cc      gdb
#       nm++    strip
#       cc++    kgdb
#       otool   ebadexec
#       ranlib  pswrap
#       kl_ld
#
#     Library Files:
#       /usr/lib/*.a
#   ```
#
# Paths were String-based (`char *`), as demonstrated by the white-paper example code in
# http://www.kevra.org/TheBestOfNext/BooksArticlesWhitePapers/WhitePapers/files/page646_5.pdf —
#
#   "For example, here is the code for a program that wishes to show the user a dialog for saving a file:"
#
#   ```
#     id save = [SavePanel new];
#     char resultFile[MAXPATHLEN];
#     [save runModalForDirectory:aDirectory name:””];
#     strcpy(resultFile, [save filename]);
#   ```
#
# Application Kit offered two environment-discovery methods, `NXUserName` and `NXHomeDirectory`,
# for the current user's name and current user's homedir respectively:
# http://www.bitsavers.org/pdf/next/Release_1_Dec90/NEXTstep_Concepts_Dec90.pdf#page=303
#
# Note the `NX` prefix, not `NS`!
#
#
# # NeXTSTEP 3.x / NeXTSTEP 486
#
# The behavior of Application Kit's `NXUserName` and `NXHomeDirectory` methods changed slightly in this release:
# https://www.nextop.de/NeXTstep_3.3_Developer_Documentation/ReleaseNotes/AppKit.htmld/index.html
#
#   "The `NXHomeDirectory()` and `NXUserName()` functions operated on the real uid of the process in 2.0.
#    After relinking in 3.0, the semantics will change to operate on the effective uid (euid) of the process
#    unless the euid of the process is zero, in which case, the real uid will be used."
#
# AppKit 3.x also added `getMountedRemovableMedia` to get a list of mounted removable-volume paths.
#
# Also see "The Interface to the File System":
# https://www.nextop.de/NeXTstep_3.3_Developer_Documentation/UserInterface/08_File/File.htmld/index.html
#
#
# # OPENSTEP / Rhapsody
#
# In OPENSTEP, the `HomeDirectory` and `UserName` methods moved from Application Kit to Foundation Kit:
# - http://www.gnustep.org/resources/documentation/Developer/Base/Reference/Functions.html#function$NSHomeDirectory
# - http://www.gnustep.org/resources/documentation/Developer/Base/Reference/Functions.html#function$NSUserName
#
# Note that they now sport the `NS` prefix as opposed to the `NX` prefixes of the Application Kit methods,
# and note how they now return `NSString`.
#
# There was also a new method to get an `NSString` of a given user name:
# - http://www.gnustep.org/resources/documentation/Developer/Base/Reference/Functions.html#function$NSHomeDirectoryForUser
#
# Despite its name, the `NSOpenStepRootDirectory` method actually appeared in Mac OS X 10.0's Foundation Kit.
#
#
# # Mac OS X
#
# "Standard Directories" are located using a combination of `Directory` and `Domain` Constants
# (to search System/Local/User/Network/All).
#
# Relevant generational changes since the time of Mac OS X 10.0 include:
# - introduction of "File Quarantine" extended-filesystem-attribute for Internet downloads in Mac OS X Leopard (10.5),
#   evolving into "Gatekeeper" in Mac OS X Lion (10.7) and beyond.
# - introduction of App Sandbox and Entitlements in Mac OS X Snow Leopard (10.6) for the Mac App Store:
#   https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/EnablingAppSandbox.html
#   (See "Enabling Access to Files in Standard Locations" especially)
# - introduction of the Swift programming language and subsequent soft-deprecation of Objective-C.
# - introduction of iCloud support (an Application's "Ubiquitous Container") in Mac OS X Lion (10.7),
#   https://developer.apple.com/documentation/foundation/optimizing_app_data_for_icloud_backup
# - preference for `NSURL`-based paths over `NSString`-based paths, e.g. to support iCloud storage.
#
# The `NS` prefixes were dropped from Swift in 3.0. Aside from that, `NSFileManager` and `FileManager` are equivalent:
# https://github.com/apple/swift-evolution/blob/main/proposals/0086-drop-foundation-ns.md
#
#
# # "Locating Items in the Standard Directories"
#
# https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/\
# AccessingFilesandDirectories/AccessingFilesandDirectories.html#//apple_ref/doc/uid/TP40010672-CH3-SW3 —
#
#   "When you need to locate a file in one of the standard directories, use the system frameworks to locate the directory first
#    and then use the resulting URL to build a path to the file. The Foundation framework includes several options for locating
#    the standard system directories. By using these methods, the paths will be correct whether your app is sandboxed or not.
#
#    - The `URLsForDirectory:inDomains:` method of the `NSFileManager` class returns a directory’s location packaged in an `NSURL` object.
#      The directory to search for is an `NSSearchPathDirectory` constant. These constants provide URLs for the user’s home directory,
#      as well as most of the standard directories.
#    - The `NSSearchPathForDirectoriesInDomains` function behaves like the `URLsForDirectory:inDomains:` method but returns
#      the directory’s location as a string-based path. Use the `URLsForDirectory:inDomains:` method instead.
#    - The `NSHomeDirectory` function returns the path to either the user’s or app’s home directory.
#      (Which home directory is returned depends on the platform and whether the app is in a sandbox.)
#      When an app is sandboxed the home directory points to the app’s sandbox, otherwise it points to the User’s home directory
#      on the file system. If constructing a file to a subdirectory of a user’s home directory,
#      consider using the `URLsForDirectory:inDomains:` method instead."
#
#
# # "Domains Determine the Placement of Files"
#
# https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/\
# FileSystemOverview/FileSystemOverview.html#//apple_ref/doc/uid/TP40010672-CH2-SW15
#
#    - The user domain contains resources specific to the users who log in to the system. Although it technically encompasses all users,
#      this domain reflects only the home directory of the current user at runtime. User home directories can reside on
#      the computer’s boot volume (in the /Users directory) or on a network volume. Each user (regardless of privileges) has access to
#      and control over the files in their own home directory.
#    - The local domain contains resources such as apps that are local to the current computer and shared among all users of that computer.
#      The local domain does not correspond to a single physical directory, but instead consists of several directories on
#      the local boot (and root) volume. This domain is typically managed by the system, but users with administrative privileges
#      may add, remove, or modify items in this domain.
#    - The network domain contains resources such as apps and documents that are shared among all users of a local area network.
#      Items in this domain are typically located on network file servers and are under the control of a network administrator.
#    - The system domain contains the system software installed by Apple. The resources in the system domain are
#      required by the system to run. Users cannot add, remove, or alter items in this domain.
#
#
# # Bookmarks
#
# `NSURL`s can be bookmarked where `NSString` paths cannot: https://developer.apple.com/documentation/foundation/nsurl —
#   "Starting with OS X v10.6 and iOS 4.0, the NSURL class provides a facility for creating and using bookmark objects.
#    A bookmark provides a persistent reference to a file-system resource."
# `NSURL` bookmarks replaced the oldschool "Alias" functionality.
#
#
# # Constant definitions:
#
# - Foundation Kit's `NSSearchPathDirectory` Enumeration defines "significant" directory location constants:
#   https://developer.apple.com/documentation/foundation/nssearchpathdirectory
#   https://developer.apple.com/documentation/foundation/filemanager/searchpathdirectory
# - Foundation Kit's `NSSearchPathDomainMask` Enumeration defines domain location constants:
#   https://developer.apple.com/documentation/foundation/nssearchpathdomainmask
#   https://developer.apple.com/documentation/foundation/filemanager/searchpathdomainmask
#
#
# # `NSString`-based Retrieval Functions available since Mac OS X 10.0
#
# - `NSSearchPathForDirectoriesInDomains` returns or an array of NSString paths:
#   https://developer.apple.com/documentation/foundation/1414224-nssearchpathfordirectoriesindoma
# - `NSHomeDirectory` returns an `NSString` path to the current user's homedir:
#   https://developer.apple.com/documentation/foundation/1413045-nshomedirectory
# - `NSHomeDirectoryForUser` is the same idea except takes a username argument:
#   https://developer.apple.com/documentation/foundation/1413447-nshomedirectoryforuser
# - `NSOpenStepRootDirectory returns the root directory of the entire system:
#   https://developer.apple.com/documentation/foundation/1414132-nsopensteprootdirectory
# - `NSTemporaryDirectory` returns the current user's temporary directory String path:
#   https://developer.apple.com/documentation/foundation/1409211-nstemporarydirectory
#
#
# # `NSURL`-based Retrieval Functions added in Mac OS X Snow Leopard (10.6)
#
# - For a single `NSURL` path:
#   https://developer.apple.com/documentation/foundation/nsfilemanager/1407693-urlfordirectory
#   https://developer.apple.com/documentation/foundation/filemanager/1407693-url
# - For an array of `NSURL` paths:
#   https://developer.apple.com/documentation/foundation/nsfilemanager/1407726-urlsfordirectory
#   https://developer.apple.com/documentation/foundation/filemanager/1407726-urls
#
#
# # Plain Ol' C
#
# This is probably the most relevant interface for me here in DistorteD Ruby-land.
#
# Before macOS 10.12, `NSSystemDirectories.h` defined an enumeration of directory constants
# and `NSSystemDirectories.c` defined a `SearchPathEnumeration` API.
# "Call NSStartSearchPathEnumeration() once, then call NSGetNextSearchPathEnumeration() one or more times
#  with the returned state. The return value of NSGetNextSearchPathEnumeration() should be used as
#  the state next time around. When NSGetNextSearchPathEnumeration() returns 0, you're done."
#
# These were available in Apple's Libc until Libc versions 9xx.x.x, corresponding to Mac OS X 10.9.x:
# - https://opensource.apple.com/source/Libc/Libc-997.90.3/include/NSSystemDirectories.h.auto.html
#
# They were also available in the Mac OS X / macOS SDK package from as far back as I can find (10.1.x)
# through macOS 10.11. After Mac OS X 10.9, they seem to disappear from Libc and are only available
# as part of the macOS SDK packages in Xcode. Smells like lock-in to me. RIP GCC.
# - https://github.com/phracker/MacOSX-SDKs/blob/master/MacOSX10.1.5.sdk/usr/include/NSSystemDirectories.h
# - https://github.com/phracker/MacOSX-SDKs/blob/master/MacOSX10.9.sdk/usr/include/NSSystemDirectories.h
# - https://github.com/phracker/MacOSX-SDKs/blob/master/MacOSX10.11.sdk/usr/include/NSSystemDirectories.h
#
#
# The constants and the `NSStartSearchPathEnumeration` API were deprecated in macOS 10.12.
# The files are still present in that version's SDK but sport a brand new deprecation warning:
# - https://github.com/phracker/MacOSX-SDKs/blob/master/MacOSX10.12.sdk/usr/include/NSSystemDirectories.h
#   "This API has been fully replaced by API in `sysdir.h`.
#    This API was deprecated because its enumerated types and many of the same identifiers
#    for those enumerated types were identical to the types and identifiers found
#    in `Foundation/NSPathUtilities.h` and including both headers caused compile errors.
#
# As the `NSSystemDirectories` deprecation warning says, macOS 10.12 introduces the new `sysdir`
# library with new constants and a new-but-similar `sysdir_start_search_path_enumeration` API.
# These files are only available in the SDK, not in Libc.
# - https://github.com/phracker/MacOSX-SDKs/blob/master/MacOSX10.12.sdk/usr/include/sysdir.h
# - https://keith.github.io/xcode-man-pages/sysdir.3.html
#
#
# # https://developer.apple.com/documentation/xcode-release-notes/xcode-10-release-notes sez:
#
# "The Command Line Tools package installs the macOS system headers inside the macOS SDK. Software that compiles
#  with the installed tools will search for headers within the macOS SDK provided by either Xcode at
# `/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.14.sdk`
#  or the Command Line Tools at `/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk` depending on which is
#  selected using `xcode-select`."
#
# "The command line tools will search the SDK for system headers by default. However, some software may fail
#  to build correctly against the SDK and require macOS headers to be installed in the base system under `/usr/include`.
#  If you are the maintainer of such software, we encourage you to update your project to work with the SDK
#  or file a bug report for issues that are preventing you from doing so.
#  As a workaround, an extra package is provided which will install the headers to the base system.
#  In a future release, this package will no longer be provided. You can find this package at
#  `/Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_10.14.pkg`."
#
# "To make sure that you’re using the intended version of the command line tools, run `xcode-select -s`
#  or `xcode select -s /Library/Developer/CommandLineTools` after installing."
#
# Isn't it great how "New Features" is the heading for this announcement that Apple are taking away
# the standard cross-platform header directory path?
#
#
# Workaround using https://clang.llvm.org/docs/ClangCommandLineReference.html#cmdoption-clang-isysroot-dir —
# ```
# export CFLAGS+=-isysroot /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk
# export CCFLAGS+=-isysroot /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk
# export CXXFLAGS+=-isysroot /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk
# export CPPFLAGS+=-isysroot /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk
# ```
#
# PureDarwin's `libcoreservices` is a possible alternative:
# - https://github.com/PureDarwin/libcoreservices
#
#
# # Carbon
#
# Constant definitions:
#  - Disk and Domain constants in Carbon are treated like volume identifiers in the Classic Toolbox:
#    http://mirror.informatimago.com/next/developer.apple.com/documentation/Carbon/Reference/Folder_Manager/\
#    folder_manager_ref/constant_11.html#//apple_ref/doc/uid/TP30000238/C005082
#  - "Folder Type" enumeration defines constants with Classic-Mac-style `OSType` (FourCC) values,
#    and most of the defined folders are things that don't exist in Mac OS X:
#    http://mirror.informatimago.com/next/developer.apple.com/documentation/Carbon/Reference/Folder_Manager/\
#    folder_manager_ref/constant_6.html#//apple_ref/doc/uid/TP30000238/C006889
#  - The "find" functions work on a `FSRef` structure, similar to a System 7 `FSSpec`
#    except not able to be introspected:
#    http://mirror.informatimago.com/next/developer.apple.com/documentation/Carbon/Reference/File_Manager/\
#    file_manager/data_type_37.html#//apple_ref/doc/c_ref/FSRef
#
#  Retrieval functions:
#  - The `FSFindFolder`/`FSFindFolderExtended` functions set a `FSRef`, and `FindFolder` returns a directory ID:
#    http://mirror.informatimago.com/next/developer.apple.com/documentation/Carbon/Reference/Folder_Manager/\
#    folder_manager_ref/function_group_2.html#//apple_ref/doc/uid/TP30000238/F16387
#  - See "Searching Within the File-System Domains":
#    http://mirror.informatimago.com/next/developer.apple.com/documentation/MacOSX/Conceptual/BPFileSystem/\
#    Concepts/Domains.html#//apple_ref/doc/uid/20002281/BAJCBACI
#
# Compare to the `FindFolder` method in Macintosh System 7.
#
# A more detailed list and explanation of the OSType constants is available here:
# http://walteriankaye.com/as/foldertypes.html
#
#
# # More (and Deprecated) Apple documentation
#
# - "macOS Standard Directories: Where Files Reside"
#   https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/\
#   FileSystemOverview/FileSystemOverview.html#//apple_ref/doc/uid/TP40010672-CH2-SW6
# - https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/LowLevelFileMgmt/Articles/StandardDirectories.html  (Deprecated)
# - https://developer.apple.com/library/archive/qa/qa1549/_index.html  "Expanding Tilde-based paths"
# - https://developer.apple.com/library/archive/qa/qa1170/_index.html  "Important Java Directories on Mac OS X"
#
#
# # GNUstep equivalents
#
# - http://www.gnustep.org/resources/documentation/Developer/Base/Reference/TypesAndConstants.html#type$NSSearchPathDirectory
# - http://www.gnustep.org/resources/documentation/Developer/Base/Reference/TypesAndConstants.html#type$NSSearchPathDomainMask
# - http://www.gnustep.org/resources/documentation/Developer/Base/Reference/Functions.html#function$NSSearchPathForDirectoriesInDomains
# - http://www.gnustep.org/resources/documentation/Developer/Base/Reference/NSFileManager.html  (Note the "unix" and "windows" path modes.)
#
#
# # Xamarin .NET equivalents
#
# - https://docs.microsoft.com/en-us/dotnet/api/foundation.nssearchpathdirectory
# - https://docs.microsoft.com/en-us/dotnet/api/foundation.nssearchpathdomain
# - https://docs.microsoft.com/en-us/dotnet/api/foundation.nsfilemanager.geturls
#
#
# Further Reading
# - https://zameermanji.com/blog/2021/7/7/getting-standard-macos-directories/
# - http://iosbrain.com/blog/2018/05/29/the-ios-file-system-in-depth/
# - https://stackoverflow.com/questions/36634632/accessing-standard-directories-on-os-x-with-c
# - https://www.techotopia.com/index.php/Working_with_Directories_on_iPhone_OS
#
# Also refer to Qt's `QStandardPath`: https://doc.qt.io/qt-6/qstandardpaths.html#StandardLocation-enum
#
#
### Alternative Path-discovery Libraries
#
# I'm not using the existing Ruby librar(y|ies) because I don't like having to instantiate `::XDG::Environment` first
# and because I want to do some stuff beyond the XDG standard such as paths for Windows/macOS.
#
# See the list at the bottom of this file for links to other similar libraries in a variety of languages.
# For implementation details we can also compare to these other XDG libraries for other programming languages:
# - C             https://github.com/Jorengarenar/libXDGdirs
# - C             https://github.com/devnev/libxdg-basedir
# - C/GLib        https://docs.gtk.org/glib/func.get_user_cache_dir.html
# - C#/.NET       https://github.com/dlech/xdg-base-directory
# - C#/.NET       https://github.com/dirs-dev/directories-net
# - C++/Qt        https://github.com/lxqt/libqtxdg
# - C++/Qt        https://doc.qt.io/qt-6/qstandardpaths.html  (Built-in since Qt 5.0)
# - C++17         https://github.com/peelonet/peelo-xdg
# - Clojure       https://github.com/derrotebaron/xdg-basedir
# - Clojure       https://github.com/ahungry/xdg-rc
# - Crystal       https://github.com/shmibs/xdg_basedir
# - D             https://github.com/FreeSlave/libxdg-basedir
# - Dart          https://github.com/flutter/packages/tree/master/packages/xdg_directories
# - Go            https://github.com/kirsle/configdir
# - Go            https://github.com/adrg/xdg
# - Go            https://github.com/zchee/go-xdgbasedir
# - Go            https://github.com/pinzolo/xdgdir
# - Go            https://github.com/kyoh86/xdg  (Deprecated)
# - Go            https://github.com/twpayne/go-xdg
# - Go            https://github.com/OpenPeeDeeP/xdg
# - Go            https://github.com/miquella/xdg
# - Go            https://github.com/BurntSushi/xdg
# - Go            https://github.com/jeremyschlatter/xdg  (Fork of BurntSushi/xdg)
# - Go            https://github.com/cardigann/xdg-go
# - Go            https://github.com/mildred/go-xdg
# - Go            https://launchpad.net/go-xdg  (And GitHub mirror https://github.com/dooferlad/go-xdg)
# - Go            https://github.com/tehbilly/xdg
# - Go            https://git.sr.ht/~adnano/go-xdg
# - Go            https://github.com/sour-is/go-xdg
# - Go            https://github.com/hawx/xdg
# - Go            https://github.com/nickwells/xdg.mod
# - Go            https://github.com/cep21/xdgbasedir
# - Go            https://github.com/subgraph/go-xdgdirs
# - Go            https://github.com/redforks/xdgdirs
# - Go            https://github.com/jcline/libxdgdatadirs
# - Go            https://github.com/tajtiattila/basedir
# - Guile Scheme  https://www.gnuvola.org/software/xdgdirs/ 
# - Haskell       https://github.com/willdonnelly/xdg-basedir
# - Java          https://www.io7m.com/software/jade/
# - Java          https://github.com/dirs-dev/directories-jvm
# - Java          https://github.com/kothar/xdg-java
# - JavaScript    https://github.com/sindresorhus/xdg-basedir
# - JavaScript    https://github.com/folder/xdg
# - JavaScript    https://github.com/mk-pmb/usher-xdg-node
# - Perl          https://metacpan.org/pod/File::XDG
# - PHP           https://github.com/dnoegel/php-xdg-base-dir
# - PHP/Laravel   https://github.com/owenvoke/laravel-xdg
# - Python        https://www.freedesktop.org/wiki/Software/pyxdg/
# - Python        https://github.com/srstevenson/xdg
# - Python        https://github.com/fenhl/python-xdg-basedir
# - Python        https://gitlab.com/deliberist/xdgenvpy
# - Python        https://gitlab.com/nobodyinperson/python3-xdgspec
# - Python        https://github.com/platformdirs/platformdirs
# - Python        https://github.com/kade-robertson/config-better
# - Python        https://launchpad.net/dirspec
# - Python        https://github.com/darkfeline/mir.xdg
# - Python        https://github.com/rec/cfgs
# - Python        https://gitlab.com/pradyparanjpe/xdgpspconf
# - Python        https://github.com/bruxisma/dirs
# - Python        https://pythonrepo.com/repo/ActiveState-appdirs-python-files
# - Racket        https://docs.racket-lang.org/basedir/index.html  (https://github.com/willghatch/racket-basedir)
# - Racket        https://github.com/lawrencewoodman/xdgbasedir_rkt
# - Ruby          https://www.alchemists.io/projects/xdg/
# - Ruby          https://github.com/rubyworks/xdg  (Gem name 'maid-xdg')
# - Rust          https://github.com/whitequark/rust-xdg
# - Rust          https://github.com/kiran-kp/xdg-basedir
# - Rust          https://github.com/xdg-rs/dirs
# - Rust          https://github.com/dirs-dev/dirs-rs         (described as "low-level")
# - Rust          https://github.com/dirs-dev/directories-rs  (described as "mid-level")
# - Rust          https://github.com/1sra3l/xdgkit
# - Rust          https://github.com/museun/configurable
# - Rust          https://github.com/bbqsrc/pathos
# - Rust          https://github.com/kade-robertson/config-better-rs
# - Scala         https://github.com/esamson/better-xdg
# - Scala         https://github.com/wookietreiber/scala-xdg
# - Tcl           https://github.com/lawrencewoodman/xdgbasedir_tcl
# - TypeScript    https://github.com/rivy/js.xdg-portable
# - TypeScript    https://github.com/rivy/js.xdg-app-paths
# - TypeScript    https://github.com/danielpza/directories-js
# (Not intended to be an exhaustive list lol)
