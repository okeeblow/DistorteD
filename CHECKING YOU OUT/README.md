# CHECKING YOU OUT

`CYO` is DistorteD's file-identification library.


## Goals

- Identify Media Types (MIME Types) for:
  - Plain filenames, file extensions, and hypothetical `Pathname`s.
  - Extended filesystem attributes for extant `Pathname`s.
  - Contents of extant files and other `IO`-like streams.
  - IETF-style Content-Type strings (e.g. 'image/jpeg') and other type identifiers like FourCCs.
  - Directory trees, e.g. `x-content/image-dcf` for digital camera cards.

- Identify files by simultaneously using as many of the above factors as possible for situations
  where a filename-only match or content-only match would be ambiguous.

- Implement the full [`shared-mime-info` specification](https://specifications.freedesktop.org/shared-mime-info-spec/shared-mime-info-spec-latest.html),
  the XDG/freedesktop-dot-org standard used on a vast majority of Linux/BSD systems.

- Automatically identify and consume all [`shared-mime-info`-format](https://specifications.freedesktop.org/shared-mime-info-spec/shared-mime-info-spec-latest.html)
  XML packages installed in the standard `$XDG_DATA_DIRS` on Linux/BSD or in normal MacPorts/Homebrew prefixes on macOS.

- Ship a built-in copy of the freedesktop-dot-org (GPLv2) and Apache Tika (MIT) package files for portability
  to Windows and to systems which haven't installed `shared-mime-info` through their package manager.

- Be as fast as possible, and [avoid as many allocations](https://www.schneems.com/2020/09/16/the-lifechanging-magic-of-tidying-ruby-object-allocations/)
  as possible by loading only the minimum necessary data from the XML packages into memory.

- Parse the `shared-mime-info` XML packages on the fly to avoid `xdg-utils`' `update-mime-database` step which I personally always found very confusing.
  I know I'm
  [not](https://help.ubuntu.com/community/AddingMimeTypes)
  [the](https://unix.stackexchange.com/questions/564816/how-to-install-a-new-custom-mime-type-on-my-linux-system-using-cli-tools)
  [only](https://help.gnome.org/admin//system-admin-guide/2.32/mimetypes-modifying.html.en)
  [person](https://help.gnome.org/admin/system-admin-guide/stable/mime-types-custom.html.en)
  [confused](https://help.gnome.org/admin/system-admin-guide/stable/mime-types-custom-user.html.en)
  [by](https://blog.robertelder.org/custom-mime-type-ubuntu/)
  [the](https://wiki.archlinux.org/title/XDG_MIME_Applications)
  [need](https://forums.linuxmint.com/viewtopic.php?t=242513)
  [to](http://wikka.puppylinux.com/HowToAddMIMEType)
  generate separate `glob2`/`magic`/etc files from the XML package files instead of using the packages directly.


## Example Usage

### Get a single Type Object

…by file extension:

`irb> CHECKING::YOU::OUT::from_postfix(:png) => #<CHECKING::YOU::OUT image/png>`

`irb> CHECKING::YOU::OUT::from_postfix('.odf') => #<CHECKING::YOU::OUT application/vnd.oasis.opendocument.formula>`

…by file path:

`irb> CHECKING::YOU::OUT::from_pathname('/home/okeeblow/224031.jpg') => #<CHECKING::YOU::OUT image/jpeg>`

…by type name:

`irb> CHECKING::YOU::OUT::from_ietf_media_type('application/rss+xml') => #<CHECKING::YOU::OUT application/rss+xml>`

…by URI:

`irb> CHECKING::YOU::OUT::from_uri("file:///home/okeeblow/hello.jpg").to_s => "image/jpeg"`

`irb> CHECKING::YOU::OUT::from_uri("HTTPS://WWW.COOLTRAINER.ORG").to_s => "x-scheme-handler/https"`

…or via the generic interface used by `CYO`'s CLI:

`irb> CHECKING::YOU::OUT('audio/ogg') => #<CHECKING::YOU::OUT audio/ogg>`

`irb> CHECKING::YOU::OUT('/home/okeeblow/2019-04-30 22-40-05.flv') => #<CHECKING::YOU::OUT video/x-flv>`

```
[okeeblow@emi#CHECKING YOU OUT] ./bin/checking-you-out TEST\ MY\ BEST/Try\ 2\ Luv.\ U/audio/mpeg/invasion_of_the_gabber_rob.mp3
audio/mpeg
```

```
[okeeblow@emi#CHECKING YOU OUT] ./bin/checking-you-out /media/okeeblow/LUMIX
x-content/image-dcf
```


### Use a single Type Object

Once retrieved, a `CYO` Type Object contains everything defined for that type across all `shared-mime-info` XML packages:

`irb> CHECKING::YOU::OUT('audio/mpeg').description => "MP3 audio"`

`irb> CHECKING::YOU::OUT('audio/mpeg').parents => #<CHECKING::YOU::IN application/octet-stream>`

`irb> CHECKING::YOU::OUT('audio/mpeg').postfixes => #<Set: {#<CHECKING::YOU::OUT::StickAround 50 *.mp3>, #<CHECKING::YOU::OUT::StickAround 50 *.mpga>}>`

`irb> CHECKING::YOU::OUT('audio/mpeg').extname => ".mp3"`

`irb> CHECKING::YOU::OUT('audio/mpeg').aka => #<Set: {#<CHECKING::YOU::IN audio/mpeg>, #<CHECKING::YOU::IN audio/x-mp3>, #<CHECKING::YOU::IN audio/x-mpg>, #<CHECKING::YOU::IN audio/x-mpeg>, #<CHECKING::YOU::IN audio/mp3>}>`


### Use multiple Type Objects simultaneously

One of the main design goals for CHECKING YOU OUT is to act as part of the interface definitions for DistorteD Modules supporting various types of files.

Let's look at [`libvips`](https://www.libvips.org/), an image library which is itself modular, relying on system libraries like `libjpeg-turbo`, `libwebp`, `libgif`, etc. VIPS' "Foreign" Loaders/Savers define a set of filename suffixes, and `libvips` has its own routing mechanism to test file names/contents and use the appropriate Foreign Loader.

My problem arises when I want to mix DistorteD's `libvips` Module with Modules supporting other totally-unrelated types of files. How can I route my files to the correct Module without wastefully trying every single one and catching the failures? VIPS provides us with a list of our installation's supported file extensions via [vips_foreign_get_suffixes()](https://www.libvips.org/API/current/VipsForeignSave.html#vips-foreign-get-suffixes). We can look at it via `ruby-vips` or via `gobject-introspection`:

```
require('gobject-introspection') unless defined?(::GObjectIntrospection)

module Vips
  Loader = ::Class::new(::GObjectIntrospection::Loader)

  begin
    Loader.load("Vips", self)
  rescue(::GObjectIntrospection::RepositoryError::TypelibNotFound)
    raise
  end
end
```

```
irb(main)> Vips::Foreign::suffixes => [".csv", ".mat", ".v", ".vips", ".ppm", ".pgm", ".pbm", ".pfm", ".hdr", ".dz", ".png", ".jpg", ".jpeg", ".jpe", ".webp", ".tif", ".tiff", ".fits", ".fit", ".fts", ".gif", ".bmp"]
```

That's a start, but what if we have a file with no extension, or with an incorrect extension (like all those CDNs serving WebP with `.jpg` file names)? I want to do my own file matching and only invoke my `libvips` Module when I'm sure I need it. CHECKING YOU OUT makes this very easy!

```
irb(main)> ::Vips::Foreign::suffixes.zip(::Vips::Foreign::suffixes.yield_self(&::CHECKING::YOU::OUT::method(:from_postfix))).to_h
=>
{".csv"=>#<struct CHECKING::YOU::OUT kingdom=:possum, phylum=:text, genus=:csv>,
 ".mat"=>#<struct CHECKING::YOU::OUT kingdom=:x, phylum=:application, genus=:"matlab-data">,
 ".v"=>#<struct CHECKING::YOU::OUT kingdom=:possum, phylum=:image, genus=:vips>,
 ".vips"=>#<struct CHECKING::YOU::OUT kingdom=:possum, phylum=:image, genus=:vips>,
 ".ppm"=>#<struct CHECKING::YOU::OUT kingdom=:x, phylum=:image, genus=:"portable-pixmap">,
 ".pgm"=>#<struct CHECKING::YOU::OUT kingdom=:x, phylum=:image, genus=:"portable-graymap">,
 ".pbm"=>#<struct CHECKING::YOU::OUT kingdom=:x, phylum=:image, genus=:"portable-bitmap">,
 ".pfm"=>#<struct CHECKING::YOU::OUT kingdom=:x, phylum=:application, genus=:"font-type1">,
 ".hdr"=>#<struct CHECKING::YOU::OUT kingdom=:x, phylum=:image, genus=:hdr>,
 ".dz"=>#<struct CHECKING::YOU::OUT kingdom=:microsoft, phylum=:image, genus=:"deep-zoom">,
 ".png"=>#<struct CHECKING::YOU::OUT kingdom=:possum, phylum=:image, genus=:png>,
 ".jpg"=>#<struct CHECKING::YOU::OUT kingdom=:possum, phylum=:image, genus=:jpeg>,
 ".jpeg"=>#<struct CHECKING::YOU::OUT kingdom=:possum, phylum=:image, genus=:jpeg>,
 ".jpe"=>#<struct CHECKING::YOU::OUT kingdom=:possum, phylum=:image, genus=:jpeg>,
 ".webp"=>#<struct CHECKING::YOU::OUT kingdom=:possum, phylum=:image, genus=:webp>,
 ".tif"=>#<struct CHECKING::YOU::OUT kingdom=:possum, phylum=:image, genus=:tiff>,
 ".tiff"=>#<struct CHECKING::YOU::OUT kingdom=:possum, phylum=:image, genus=:tiff>,
 ".fits"=>#<struct CHECKING::YOU::OUT kingdom=:possum, phylum=:image, genus=:fits>,
 ".fit"=>#<struct CHECKING::YOU::OUT kingdom=:possum, phylum=:image, genus=:fits>,
 ".fts"=>#<struct CHECKING::YOU::OUT kingdom=:possum, phylum=:image, genus=:fits>,
 ".gif"=>#<struct CHECKING::YOU::OUT kingdom=:possum, phylum=:image, genus=:gif>,
 ".bmp"=>#<struct CHECKING::YOU::OUT kingdom=:possum, phylum=:image, genus=:bmp>}
```

```
irb(main)> ::Vips::Foreign::suffixes.yield_self(&::CHECKING::YOU::OUT::method(:from_postfix)).uniq.map(&:inspect)
=>
["#<CHECKING::YOU::OUT text/csv>",
 "#<CHECKING::YOU::OUT application/x-matlab-data>",
 "#<CHECKING::YOU::OUT image/vips>",
 "#<CHECKING::YOU::OUT image/x-portable-pixmap>",
 "#<CHECKING::YOU::OUT image/x-portable-graymap>",
 "#<CHECKING::YOU::OUT image/x-portable-bitmap>",
 "#<CHECKING::YOU::OUT application/x-font-type1>",
 "#<CHECKING::YOU::OUT image/x-hdr>",
 "#<CHECKING::YOU::OUT image/vnd.microsoft.deep-zoom+xml>",
 "#<CHECKING::YOU::OUT image/png>",
 "#<CHECKING::YOU::OUT image/jpeg>",
 "#<CHECKING::YOU::OUT image/webp>",
 "#<CHECKING::YOU::OUT image/tiff>",
 "#<CHECKING::YOU::OUT image/fits>",
 "#<CHECKING::YOU::OUT image/gif>",
 "#<CHECKING::YOU::OUT image/bmp>"]
```

Boom, now we're defining our Module interface with live Objects instead of with Strings! All we have to do is perform the same matching on an individual file and connect the dots.

```
irb(main)> ::CHECKING::YOU::OUT::from_pathname("/home/okeeblow/224031.jpg") => #<struct CHECKING::YOU::OUT kingdom=:possum, phylum=:image, genus=:jpeg>
```

## Alternatives

- `CYO` aims to implement the whole `shared-mime-info` specification and be fast and generally awesome,
but it is designed around my specific need for a "fast inner loop" of file/stream identification in DistorteD.
Please consider if one of these other Ruby libraries meets your needs before choosing `CHECKING YOU OUT`:


- [`ruby-mime-types`](https://github.com/mime-types/ruby-mime-types) and its associated [`mime-types-data`](https://github.com/mime-types/mime-types-data)
were my original choice for DistorteD, and the first version of `CYO` wrapped this library to provide `DD`-specific methods and custom additional type data.
This library determines type based on file extensions (e.g. `hello.jpg` ➔ `[#<MIME::Type: image/jpeg>]`) and does not provide "magic" file-content matching.
Its API [descends from](https://github.com/mime-types/ruby-mime-types/blob/ca89015739efe42e12c279823190dba9bcaaf6b6/History.rdoc#label-1.003)
Mark Overmeer's [`MIME-Types`](http://perl.overmeer.net/CPAN/#MIME-Types) Perl module.
Its type data comes [from Apache HTTPd's Media Type list](https://github.com/mime-types/mime-types-data/blob/master/support/apache_mime_types.rb)
and [from IANA's Media Type registry](https://github.com/mime-types/mime-types-data/blob/master/support/iana_registry.rb) and is usually updated [several times per year](https://github.com/mime-types/mime-types-data/tags).


- [`mimemagicrb`](https://github.com/mimemagicrb/mimemagic) was popular in Rails circles via Rails' wrapper before that wrapper became standalone.
Like `CYO`, `mimemagicrb` uses `freedesktop.org`'s `shared-mime-info`-format database as a data source.
Unlike `CYO`, `mimemagicrb` does a one-time transformation of `shared-mime-info.xml` to load file extensions and content-matching sequences into memory
then queries itself from there. That transformation used to happen once at Gem package time with the transformed data shipping as part of the Gem, but it [became a runtime transformation](https://github.com/mimemagicrb/mimemagic/commit/f95088a05bcf07fbad73c350db1e2b9fe4a0441e#diff-fc52eb3b499c02ca79f89e62ac2cc41c160f4759942a36730cb50e89908a5b03)
following a [license-incompatibility issue](https://github.com/mimemagicrb/mimemagic/issues/97) between the database's GPLv2 and the library's MIT license.
The library authors' attempts to clean up the older infringing Gem versions resulted in a
[shameful](https://github.com/mimemagicrb/mimemagic/issues/98)
[outpouring](https://old.reddit.com/r/ruby/comments/mc5bpe/mimemagic_versions_prior_to_036_have_been_yanked/)
[of](https://old.reddit.com/r/ruby/comments/mdriyy/all_versions_of_mimemagic_on_rubygemsorg_are_now/)
[hate](https://github.com/rails/rails/issues/41750) from underprepared members of the Rails "community" toward these *volunteers*
in a fantastic display of the same attitudes that kept me away from Ruby entirely for over a decade.
This library now requires a separate upfront installation of `shared-mime-info.xml` in a well-known filesystem location,
usually accomplished via `Homebrew` or some other package manager.

- [`mini_mime`](https://github.com/discourse/mini_mime) is an alternative representation of [`mime-types-data`](https://github.com/mime-types/mime-types-data) focused on performance above all else. It does not load `mime-types-data` at runtime, instead [processing it](https://github.com/discourse/mini_mime/blob/ecaaffd63fe5cc86cdc3cbef42cde0aa81e47832/Rakefile#L34) into flat text files which are then [locked and binary-searched](https://github.com/discourse/mini_mime/blob/63802d1e45cb2b831c34b5d68e364b5ea35c050a/lib/mini_mime.rb#L52-L75) during lookup.

- [`marcel`](https://github.com/rails/marcel/) is Rails' file-typing library, originally a `mimemagicrb` wrapper which
[became standalone](https://github.com/rails/marcel/commit/2e58d1986715420f0abbba060b6e158d6f4d3a05) at the time of the license drama.
This library uses the `shared-mime-info` format but not the usual GPLv2 `freedesktop.org` database in that format.
Apache's Tika project supplies an alternative MIT-licensed XML package file which Marcel
[transforms to regular Ruby `Hash`es](https://github.com/rails/marcel/blob/main/script/generate_tables.rb)
as part of [its release cycle](https://github.com/rails/marcel/blob/main/Rakefile).

### Feature Matrix

| | CHECKING YOU OUT | [`ruby-mime-types`](https://github.com/mime-types/ruby-mime-types) | [`mimemagicrb`](https://github.com/mimemagicrb/mimemagic) | [`mini_mime`](https://github.com/discourse/mini_mime) | [`marcel`](https://github.com/rails/marcel/) |
|---|---|---|---|---|---|
| *License*             | AGPLv3 for CYO; [GPLv2]()/[APLv2](https://www.gnu.org/licenses/license-list.en.html#apache2) for bundled data | [MIT](https://github.com/mime-types/ruby-mime-types/blob/main/Licence.md) | [MIT](https://github.com/mimemagicrb/mimemagic/blob/master/LICENSE) | [MIT](https://github.com/discourse/mini_mime/blob/master/LICENSE.txt) | [APLv2](https://github.com/rails/marcel/blob/main/APACHE-LICENSE)/[MIT](https://github.com/rails/marcel/blob/main/MIT-LICENSE) |
| *Native Data Format*         | Implements the [`shared-mime-info`](https://specifications.freedesktop.org/shared-mime-info-spec/latest/) specification via its XML package files, not via `update-mime-database`'s output. | [IANA Media-Type registry and Apache `httpd`](https://github.com/mime-types/mime-types-data/blob/219ebc3045839daafab93227c69c14bb5afd7be1/Rakefile#L51-L63) type data. | Any [one (1) `shared-mime-info` package](https://github.com/mimemagicrb/mimemagic/blob/b5ca5382125712a3f095fdb6c4f5b5ccd0dd318f/lib/mimemagic/tables.rb#L67-L75). | [`ruby-mime-types` data transformed at package time](https://github.com/discourse/mini_mime/blob/ecaaffd63fe5cc86cdc3cbef42cde0aa81e47832/Rakefile#L36). | `shared-mime-info` packages [bundled with Marcel and transformed at package time](https://github.com/rails/marcel/blob/2e58d1986715420f0abbba060b6e158d6f4d3a05/Rakefile#L35-L39) into custom structures. |
| *Bundled Data*        | [freedesktop-dot-org](https://gitlab.freedesktop.org/xdg/shared-mime-info/-/blob/master/data/freedesktop.org.xml.in), [Apache Tika](https://gitbox.apache.org/repos/asf?p=tika.git;a=blob;f=tika-core/src/main/resources/org/apache/tika/mime/tika-mimetypes.xml;hb=HEAD), and CYO-specific `shared-mime-info` packages. | Separate [`mime-types-data` Gem](https://github.com/mime-types/mime-types-data) from the same maintainer. | [No](https://github.com/mimemagicrb/mimemagic#dependencies). | [Yes](https://github.com/discourse/mini_mime/tree/master/lib/db). | [Apache Tika and Marcel-specific](https://github.com/rails/marcel/tree/main/data) `shared-mime-info` packages. |
| *External Data*       | Automatically loads all `shared-mime-info` packages [in `$XDG_DATA_DIRS` or `$XDG_DATA_HOME`](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html), and one-off `CYO` objects can be added by `::CHECKING::YOU::OUT::send`ing them to one of the running CYO `::Ractor`s. | One-off `MIME::Type` objects can be added with [`MIME::Type's ::add`](https://github.com/mime-types/ruby-mime-types/blob/35cc02d983479850b229faa58b21fc80f568f698/lib/mime/types.rb#L162-L183), or the entire database can be replaced usin a custom [`Loader`](https://github.com/mime-types/ruby-mime-types/blob/main/lib/mime/types/loader.rb).[^1] | It can be configured to load any [one(1)](https://github.com/mimemagicrb/mimemagic#dependencies) `shared-mime-info` package, and one-off Types can be defined with [`MimeMagic's ::add`](https://github.com/mimemagicrb/mimemagic/blob/641561de3f2451dde562ab90279658b5a3efcf08/lib/mimemagic.rb#L20-L36). | Technically possible but [only by complete replacement](https://github.com/discourse/mini_mime/blob/63802d1e45cb2b831c34b5d68e364b5ea35c050a/lib/mini_mime.rb#L24-L25) of the data files, [supported via confiuration](https://github.com/discourse/mini_mime#configuration). |  One-off type definitions can be added with [`Marcel::MimeType's ::extend`](https://github.com/rails/marcel/blob/main/lib/marcel/mime_type/definitions.rb), or the entire database can be replaced by [monkey-patching the generated tables](https://github.com/rails/marcel/blob/main/lib/marcel/tables.rb). |


[^1]: I used to do this for my custom additions when CYO was a `ruby-mime-types` wrapper.


| | CHECKING YOU OUT | [`ruby-mime-types`](https://github.com/mime-types/ruby-mime-types) | [`mimemagicrb`](https://github.com/mimemagicrb/mimemagic) | [`mini_mime`](https://github.com/discourse/mini_mime) | [`marcel`](https://github.com/rails/marcel/) |
|---|---|---|---|---|---|
| *File extension matching*[^2]          | ☑ | ☑ | ☑ | ☑ | ☑ |
| *Filename pattern matching*[^3]        | ☑ | ☐ | ☐ | ☐ | ☐ |
| *File content matching*[^4]            | ☑ | ☐ | ☑ | ☐ | ☑ |
| *Non-regular file matching*[^5]        | ☑ | ☐ | ☐ | ☐ | ☐ |
| *Directory tree matching*[^6]          | ☑ | ☐ | ☐ | ☐ | ☐ |
| *URI scheme matching*[^7]              | ☑ | ☐ | ☐ | ☐ | ☐ |
| *XML root/namespace matching*[^8]      | ☑ | ☐ | ☐ | ☐ | ☐ |
| *FourCC matching*[^9]                  | ☐ | ☐ | ☐ | ☐ | ☐ |
| *GUID matching*[^10]                   | ☐ | ☐ | ☐ | ☐ | ☐ |
| *UTI support*[^11]                     | ☐ | ☐ | ☐ | ☐ | ☐ |
| *Multi-factor matching*[^12]           | ☑ | ☐ | ☐ | ☐ | ☑ |
| *Partial data loading*[^13]            | ☑ | ☐ | ☐ | ☑ | ☐ |
| *Extended filesystem attributes*[^14]  | ☑ | ☐ | ☐ | ☐ | ☐ |
| *Parent/Child type relationships*[^15] | ☑ | ☐ | ☐ | ☐ | ☐ |

[^2]: e.g. `.jpg` => `image/jpeg`.
[^3]: e.g. `Makefile.<anything>` => `text/x-makefile`.
[^4]: à la [`file`/`libmagic`](http://darwinsys.com/file/).
[^5]: e.g. `inode/mount-point`, `inode/directory`, etc.
[^6]: e.g. `DCIM/<pictures>` => `x-content/image-dcf`.
[^7]: e.g. `https://cooltrainer.org` => `x-scheme-handler/https`.
[^8]: e.g. a plain `*.xml`-named file with root-Element `<svg>` and XML namespace `http://www.w3.org/2000/svg` => `image/svg+xml`.
[^9]: à la Classic Macintosh or [DirectShow](https://gix.github.io/media-types/), e.g. `MJPG` => `#<Type video/x-mjpeg>`.
[^10]: à la [Media Foundation](https://gix.github.io/media-types/), e.g. `{47504A4D-0000-0010-8000-00AA00389B71}` => `#<Type video/x-mjpeg>`.
[^11]: à la [macOS](https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/UTIRef/Articles/System-DeclaredUniformTypeIdentifiers.html#//apple_ref/doc/uid/TP40009259-SW1), e.g. `com.compuserve.gif` => `#<Type image/gif>`.
[^12]: i.e. testing multiple of the above factors (extname, filename glob, byte sequences, XML namespace) simultaneously for a given `Pathname`.
[^13]: i.e. optimizing startup time and minimizing memory usage by loading type data on-demand instead of loading all types in one shot.
[^14]: e.g. `user.mime_type` containing IETF-style media/subtype strings.
[^15]: e.g. a `#<Type image/svg+xml>` would know it has a parent `#<Type application/xml>`.

Note: Reference links are to specific revisions so it's clear what I was writing about. I would feel bad if one of these other libraries added a new feature and I was here still saying otherwise :)

### Honorable mentions

- [`mahoro`](https://yhbt.net/mahoro.git/) is a [`libmagic`](http://www.darwinsys.com/file/) binding which I haven't tried, but it [looks nice](https://yhbt.net/mahoro/API) and is maintained.

- [`shared-mime-info`](https://github.com/hanklords/shared-mime-info) is a Ruby Gem not to be confused with the [specification of the same name](). Unlike CYO, this library [consumes the `glob`/`magic` files](https://github.com/hanklords/shared-mime-info/blob/7b105f3ed7e8b34f0e14a9d573f4500d85679ca7/lib/shared-mime-info.rb#L300-L306) generated by the [`update-mime-database`](https://cgit.freedesktop.org/xdg/shared-mime-info/tree/src/update-mime-database.c) utility instead of consuming the source XML package files directly.

- [`ruby-filemagic`](https://github.com/blackwinter/ruby-filemagic/) and [`ffiruby-filemagic`](https://github.com/glongman/ffiruby-filemagic/) are bindings to [`libmagic`](http://www.darwinsys.com/file/). I used both of these (not simultaneously) in the past to supplement `ruby-mime-types` with file-content matching. These rely on the external `magic` library, usually installed through a system-level package manager [such as Homebrew](https://formulae.brew.sh/formula/libmagic). These preclude Windows support, and `ruby-filemagic` [is unmaintained](https://github.com/blackwinter/ruby-filemagic/commit/e1f2efd07da4130484f06f58fed016d9eddb4818).

- [`sixarm_ruby_magic_number_type`](https://github.com/SixArm/sixarm_ruby_magic_number_type) is a lightweight content-matching library with [its own small type database](https://github.com/SixArm/sixarm_ruby_magic_number_type/blob/main/lib/sixarm_ruby_magic_number_type/string.rb#L28) which works by [monkey-patching Ruby's built-in `::File`, `::IO`, and `::String` classes](https://github.com/SixArm/sixarm_ruby_magic_number_type/tree/main/lib/sixarm_ruby_magic_number_type).

## GreeTz

- @ohler55 for [`ox`](https://github.com/ohler55/ox), the only Ruby XML library I found that could parse `freedesktop.org.xml` faster than `ruby-mime-types` took to load.
- @dearblue for [`ruby-extattr`](https://github.com/dearblue/ruby-extattr).
- @minad — you did the right thing.
