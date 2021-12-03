The plan keeps coming up again,
and the plan means nothing stays the same,
but the plan won't accomplish anything
if it's not implemented 𝅘𝅥𝅮


# Currently Thinking About…

- Building things with `Ractor` architectures where it makes sense to do so.
  - There's no way I'll be able to `Ractor`-ize everything any time soon due to lack of support in both `Fiddle` and the more-popular `FFI` gem.
  - [`gobject-introspection`](https://github.com/ruby-gnome/ruby-gnome/commits/master/gobject-introspection) has had some `Ractor`-ization work but I don't think it's usable yet. I might end up writing my own minimal VIPS binding once it is.
- Versioning scheme. I might end up switching to monotonic incrementing versions instead of trying to decide what warrants a new major/minor SemVer.


## CHECKING YOU OUT

- [Polyglot file](https://github.com/corkami/docs/blob/master/AbusingFileFormats/README.md) identification, e.g. manually-concatenated JFIF+ZIP files or EXE/DLL files constructed with [`RezWack`](https://www.unix.com/man-page/osx/1/RezWack/).
- FourCC support:
  - Fill out FourCC type definitions in local XML packages.
  - No `String` representations — ensure FourCCs can contain `0x0` like the pre-QT5 MP3 type.
- (Ongoing) Test fixtures:
  - Aim for relatively full coverage of matchable types.
  - Aim for a wide range of generating applications to hit as many variations in type specification as possible, e.g. older and newer PDF/PS versions.
- Find a way to rectify differences between the fd.o and Tika package definitions. Maybe just get rid of the Tika package and bring its useful definitions into this tree.
- Integrate [`ruby-gettext/locale`](https://github.com/ruby-gettext/locale) to choose one (1) appropriate `<comment>` translation. I've been working with the `freedesktop.org.xml.in` package without translations.
- Support extracting a single member of multi-stream files like Zip archives or Mac Resources. This might end up being a separate service from CYO, but since there's so much identification involved there's a strong argument for doing it here.
- Test on Winders at least once — probably not on an ongoing basis.
- (Future) Upstream my homegroan type definitions to the freedesktop-dot-org project after they have time to mature.
- Pull cross-OS/cross-Desktop/cross-CPU t00lz out into their own (small) Gem once I need to re-use them.


## Passive Goals

- Optimize for startup performance:
  - Avoid as much filesystem interaction as possible, [even `stat`ing files](https://old.reddit.com/r/ruby/comments/aqxepw/rubys_startup_time_seems_to_get_worse/)!
  - [Prefer `require_relative`](https://bugs.ruby-lang.org/issues/12973) for same reason as above.
  - Avoid `require`ing dependencies up front if possible, e.g. GStreamer is very slow
    but doesn't need to be loaded unless we are working with audio/video.
- Remove/avoid dependencies on native-OS libraries where possible,
  e.g. for something like filemagic where the library functionality is a means to an end
  but not for something like VIPS where the library is the draw because it's so good.
