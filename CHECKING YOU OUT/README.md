# CHECKING YOU OUT

DistorteD's file-identification library — For any input, CYO identifies a matching Media Type, returning an Object that encapsulates all known facts about that Type.

Canonical URIs for this document:
- [https://cooltrainer.org/distorted/checking-you-out/](https://cooltrainer.org/distorted/checking-you-out/)
- [https://github.com/okeeblow/DistorteD/tree/NEW SENSATION/CHECKING YOU OUT](https://github.com/okeeblow/DistorteD/tree/NEW%E2%80%85SENSATION/CHECKING%20YOU%20OUT)

## Requirements

- Ruby, usually the latest yearly stable version (deal w/ it)
- [ox](https://github.com/ohler55/ox) to parse `shared-mime-info` Media Type definitions
- [ruby-extattr](https://github.com/dearblue/ruby-extattr) for reading and writing extended file attributes
- [addressable](https://github.com/sporkmonger/addressable) as a fully-featured alternative to Ruby's stdlib [uri](https://github.com/ruby/uri)

## Theory

Almost every possible interaction one would want to have with a computer will involve reading and writing [data records](https://en.wikipedia.org/wiki/Record_(computer_science)). In almost all cases, those data records take the form of byte streams. Believe it or not [there are computers where that is not always the case](https://www.ibm.com/docs/en/zos-basic-skills?topic=set-data-record-formats), but [those computers don't run my code](https://www.ibm.com/docs/en/zos-basic-skills?topic=zos-programming-languages), so, like, whatever. Because a stream is just bytes, [it may contain anything](https://www.youtube.com/watch?v=xSZqX5Io6AY) — prose, audio, video, computer code, a compiled executable, some other structured format containing a deeper level of data records — anything. Deriving a "type" with CHECKING YOU OUT lets our computer choose what to do with those bytes without having to be told, and translating between type systems makes it possible to exchange data records with other computers running different software. Much like the current date & time or the worth of money, the actual value we choose to describe a data record's type is meaningless — the only thing that matters is that two or more parties agree that some value has a shared meaning and should result in the same action.

When working with local streams ("files"), some filesystems provide an explicit out-of-band way to assign and query a data record's type. The most notable example is the Classic (20th century) Mac OS where [use of type and creator codes is non-optional](https://spinsidemacintosh.neocities.org/im202.html#im024-002). Any filesystem supporting [extended attributes](https://en.wikipedia.org/wiki/Extended_file_attributes) can achieve something similar on 21st-century operating systems, but in practice nobody uses them. The dominance of [CP/M-influenced](https://en.wikipedia.org/wiki/CP/M#File_system) operating systems like DOS and Windows means much of the computing world has settled on the using the lowest common denominator: signaling a data record's type in-band with its name, like how a file named `hello.jpg` is a data record named `hello` marked as a JPEG image by the `.jpg` "file extension". Besides file extensions, some standards rely on well-known names and locations for certain directories/files/trees, like how `DCIM` is the [standardized](https://en.wikipedia.org/wiki/Design_rule_for_Camera_File_system) directory name for digital camera images on removable storage.

When accessing data records via Internet protocols, we mostly have to deal with protocol headers defining the type of the enclosed stream as a string of characters matching the form `<category-name>/<type-name>`. For example, the document you're currently reading is represented by [`text/markdown`](http://www.iana.org/assignments/media-types/text/markdown) in its source form, or as [`text/html`](https://datatracker.ietf.org/doc/html/rfc2854) when transformed for consumption through a web browser. This representation is frequently referred to as a "[MIME Type](https://en.wikipedia.org/wiki/MIME#Content-Type)" due to the form [being created](https://www.rfc-editor.org/rfc/rfc2045#section-5) as part of Multipurpose Internet Mail Extensions in the '90s. The term "Media Type" or "Content Type" is [preferred these days](https://www.rfc-editor.org/rfc/rfc6838#section-1.1) to reflect this type system's spread to non-mail protocols like HTTP.

Both of those conventions have flaws.

Deriving a file's type from its name obviously makes it possible for users to edit that file name and add the wrong file extension or remove the extension entirely, rendering their files unusable when their computer has no associated application or associates an incompatible application. This became such a widespread problem in Windows-land that Microsoft created a double usability failure by hiding the in-band file extension from view by default. With the dominance of Wintel, [other mass-market operating systems followed suit](https://support.apple.com/guide/mac-help/show-or-hide-filename-extensions-on-mac-mchlp2304/mac). Besides being very annoying, this hidden legacy provides a passive social-engineering vector for malware, famously seen with [ILOVEYOU](https://en.wikipedia.org/wiki/ILOVEYOU)'s `LOVE-LETTER-FOR-YOU.TXT.vbs`.

On the Web we usually get some sort of in-band filename metadata as [part of the URI](https://www.rfc-editor.org/rfc/rfc3986#section-3.3) in addition to the `Content-Type` HTTP header, so it seems as though we have multiple pieces of identifying information. Unfortunately, most web servers derive the `Content-Type` from… (wait for it)… the file extension! See Apache's [`mime.types`](https://svn.apache.org/repos/asf/httpd/httpd/trunk/docs/conf/mime.types), Nginx's [`mime.types`](https://trac.nginx.org/nginx/browser/nginx/conf/mime.types), or Rack's [`mime.rb`](https://github.com/rack/rack/blob/main/lib/rack/mime.rb) for example.

The reality is that we can't *rely* on any of that stuff. They're *usually* correct, except when they aren't.

To double-check, we have to open up the data record and look at its structure — another type of in-band signaling known as [content sniffing](https://en.wikipedia.org/wiki/Content_sniffing). This approach is historically common on UNIX-like systems in the form of [Ian Darwin's `file`](http://darwinsys.com/file/) and its associated database of "[`magic`](https://github.com/file/file/tree/master/magic/Magdir)" signatures, named for the concept of "[magic bytes](https://en.wikipedia.org/wiki/List_of_file_signatures)". The `magic` database can identify a fantastic selection of esoteric formats, but CYO doesn't use it because it does a poor job covering filename metadata and Internet-style types and is really only designed for consumption by the `file` program itself.

CYO uses type signature definitions in the XDG/freedesktop-dot-org [`shared-mime-info` XML format](https://specifications.freedesktop.org/shared-mime-info-spec/shared-mime-info-spec-latest.html). This specification came about in the early 2000s as a standardization effort among GNOME/KDE/ROX/etc desktop environments and (as the name implies) is intentionally not coupled to any one software implementation. Besides defining the specification, freedesktop provide their own GPLv2-licensed [package of type definitions](https://gitlab.freedesktop.org/xdg/shared-mime-info/-/blob/master/data/freedesktop.org.xml.in) conforming to that specification, as well as a reference implementation of software to consume those definitions (`xdg-utils`).

With `xdg-utils`, adding or changing any `shared-mime-info` XML definitions requires a user to manually run [`update-mime-database`](https://gitlab.freedesktop.org/xdg/shared-mime-info/-/blob/master/src/update-mime-database.c) with permission to write to system shared directories. The `update-mime-database` utility processes all available XML packages into an array of single-purpose files, e.g. `globs2` containing filename metadata, `magic` containing stream-structure metadata, `subclasses` containing parent/child type relationships, and *those* files are what the `xdg-mime` frontend consumes instead of the source XML. Personally I have always found `xdg-utils`' two-step process to be very confusing and error-prone,
and I know
[I'm](http://wikka.puppylinux.com/HowToAddMIMEType)
[not](https://help.ubuntu.com/community/AddingMimeTypes)
[the](https://unix.stackexchange.com/questions/564816/how-to-install-a-new-custom-mime-type-on-my-linux-system-using-cli-tools)
[only](https://help.gnome.org/admin//system-admin-guide/2.32/mimetypes-modifying.html.en)
[person](https://help.gnome.org/admin/system-admin-guide/stable/mime-types-custom.html.en)
[frequently](https://help.gnome.org/admin/system-admin-guide/stable/mime-types-custom-user.html.en)
[stymied](https://blog.robertelder.org/custom-mime-type-ubuntu/)
[by](https://wiki.archlinux.org/title/XDG_MIME_Applications)
[it](https://forums.linuxmint.com/viewtopic.php?t=242513).

CHECKING YOU OUT avoids that whole mess by reading the raw `shared-mime-info` XML packages directly, so it never needs more than read-only access to the computer environment and doesn't need `xdg-utils` or its post-processed files in any way. There are other Ruby libraries which also work this way (e.g. `mimemagicrb`), but CYO beats them all on memory usage, performance, and number of supported features! As content sniffing is not a panacea, CYO will use any and all available approaches for fingerprinting the contents of an unknown stream: filename metadata, "magic" bytes, extended filesystem attributes, URI scheme, and any other attribute that can inform a decision. CYO ships with many of my own homegroan type definitions in `shared-mime-info` format as well as a copy of the upstream freedesktop package, but it will always prefer a newer system-wide version of the freedesktop package over its bundled copy. No version of CYO can ever become stale!

## Basic Usage

The recommended way to use CHECKING YOU OUT is via its generic interface which will try to Do The Right Thing™ for any given input:
- `Pathname`s and `String`s representing nonextant files will test the file name and path.
- `Pathname`s and `String`s representing extant files will test the file name, file path, and the byte stream structure.
- `URI`s will test the file name, URI path, URI scheme, and the byte stream structure iff it's a local record.
- `String`s and `Symbol`s will be tested for equality with known IANA Content-Types and known file extensions.


For example:

```
irb> CHECKING::YOU::OUT('audio/ogg')
=> #<CHECKING::YOU::OUT audio/ogg>

irb> CHECKING::YOU::OUT('/home/okeeblow/hello.jpg')
=> #<CHECKING::YOU::OUT image/jpeg>

irb> CHECKING::YOU::OUT(Pathname::new('~/2019-04-30 22-40-05.flv').expand_path)
=> #<CHECKING::YOU::OUT video/x-flv>

irb> CHECKING::YOU::OUT('file:///home/okeeblow/meatspin.gif')
=> #<CHECKING::YOU::OUT image/gif>

irb> CHECKING::YOU::OUT('.docx')
=> #<CHECKING::YOU::OUT application/vnd.openxmlformats-officedocument.wordprocessingml.document>

irb> CHECKING::YOU::OUT(:md)
=> #<CHECKING::YOU::OUT text/markdown>

irb> CHECKING::YOU::OUT(Addressable::URI::parse("HTTPS://COOLTRAINER.ORG"))
=> #<CHECKING::YOU::OUT x-scheme-handler/https>
```


The retrieved `CYO` Type Object encapsulates every fact defined for that type across all `shared-mime-info` XML packages, e.g.:

```
irb> CHECKING::YOU::OUT('audio/mpeg').description
=> "MP3 audio"

irb> CHECKING::YOU::OUT('audio/mpeg').parents
=> #<CHECKING::YOU::IN application/octet-stream>

irb> CHECKING::YOU::OUT('audio/mpeg').sinistar
=> #<Set: {#<CHECKING::YOU::OUT::DeusDextera 50 *.mp3>, #<CHECKING::YOU::OUT::DeusDextera 50 *.mpga>}>

irb> CHECKING::YOU::OUT('audio/mpeg').extname
=> ".mp3"

irb> CHECKING::YOU::OUT('audio/mpeg').aka
=> #<Set: {#<CHECKING::YOU::IN audio/mpeg>, #<CHECKING::YOU::IN audio/x-mp3>, #<CHECKING::YOU::IN audio/x-mpg>, #<CHECKING::YOU::IN audio/x-mpeg>, #<CHECKING::YOU::IN audio/mp3>}>
```


## CLI Usage

CYO includes a very basic command-line wrapper for the generic interface, useful for quick tests on specific inputs:

```
[okeeblow@emi#CHECKING YOU OUT] ./bin/checking-you-out ~/invasion_of_the_gabber_rob.mp3
audio/mpeg
```

```
[okeeblow@emi#CHECKING YOU OUT] ./bin/checking-you-out /media/okeeblow/LUMIX
x-content/image-dcf
```


## Specific Usage

If only a single matching criterion is needed, there are specific interfaces to match…

…by file extension:

```
irb> CHECKING::YOU::OUT::from_postfix(:png)
=> #<CHECKING::YOU::OUT image/png>

irb> CHECKING::YOU::OUT::from_postfix('.odf')
=> #<CHECKING::YOU::OUT application/vnd.oasis.opendocument.formula>
```

…by file path:

```
irb> CHECKING::YOU::OUT::from_pathname('/home/okeeblow/meatspin.gif')
=> #<CHECKING::YOU::OUT image/gif>
```

…by type name:

```
irb> CHECKING::YOU::OUT::from_iana_media_type('application/rss+xml')
=> #<CHECKING::YOU::OUT application/rss+xml>
```

…by URI:

```
irb> CHECKING::YOU::OUT::from_uri("file:///home/okeeblow/hello.jpg")
=> #<CHECKING::YOU::OUT image/jpeg>

irb> CHECKING::YOU::OUT::from_uri("HTTPS://WWW.COOLTRAINER.ORG")
=> #<CHECKING::YOU::OUT x-scheme-handler/https>
```


## Interface Usage

One of the main design goals for CHECKING YOU OUT is to act as part of the interface definitions for DistorteD Modules supporting various media types when those supported types are defined in heterogenous ways. See how we can successfully match dissimilar criteria against each other when those criteria resolve to the same Type:

```
irb> ::CHECKING::YOU::OUT::from_iana_media_type('audio/mpeg') == ::CHECKING::YOU::OUT::from_postfix('.mp3')
=> true
```

For a working example, let's look at [`libvips`](https://www.libvips.org/): an image library which is itself modular, relying on system libraries like `libjpeg`, `libwebp`, `libgif`, etc. For every available supported library, VIPS exposes a corresponding "Foreign" "Loader" and/or "Saver" class. At runtime, `libvips` has its own routing mechanism to test file names/contents and use the appropriate Foreign Loader/Saver.

My problem arises when I want to mix DistorteD's `libvips` Module with Modules supporting other totally-unrelated types of files. How can I route my image files through the VIPS Module without wastefully trying every single Module and catching the failures? We need to know what types VIPS supports, which it will enumerate via [vips_foreign_get_suffixes()](https://www.libvips.org/API/current/VipsForeignSave.html#vips-foreign-get-suffixes). The `get_suffixes` function only enumerates Saver types and only returns a list of the relevant types' file extensions ("suffixes") including duplicates like `jpg`/`jpeg`/`jpe`. We can test it via `ruby-vips` or via `gobject-introspection` with e.g.:

```
irb> require('gobject-introspection') unless defined?(::GObjectIntrospection)
=> true

irb* module Vips
irb*   Loader = ::Class::new(::GObjectIntrospection::Loader)
irb*   begin
irb*     Loader.load("Vips", self)
irb*   rescue(::GObjectIntrospection::RepositoryError::TypelibNotFound)
irb*     raise  # Would emit missing-libvips message here in real code
irb*   end
irb> end
=> nil

irb> Vips::Foreign::suffixes
=> [".csv", ".mat", ".v", ".vips", ".ppm", ".pgm", ".pbm", ".pfm", ".hdr", ".dz", ".png", ".jpg", ".jpeg", ".jpe", ".webp", ".tif", ".tiff", ".fits", ".fit", ".fts", ".gif", ".bmp"]
```

That's a start, but what if we have a file with no extension or with an incorrect extension (like from CDNs serving WebP with `.jpg` file names)? I want to do my own much-more-pedantic file matching and only invoke my `libvips` Module once I'm sure I need it. CHECKING YOU OUT makes this very easy — we can feed that list of file extensions to one of CYO's entrypoint methods and resolve them to Type Objects in a single shot!

```
irb* ::Vips::Foreign::suffixes.zip(
irb*   ::Vips::Foreign::suffixes.yield_self(&::CHECKING::YOU::OUT::method(:from_postfix))
irb> ).to_h
=>
{".csv"=>#<CHECKING::YOU::OUT text/csv>,
 ".mat"=>#<CHECKING::YOU::OUT application/x-matlab-data>,
 ".v"=>#<CHECKING::YOU::OUT image/vips>,
 ".vips"=>#<CHECKING::YOU::OUT image/vips>,
 ".ppm"=>#<CHECKING::YOU::OUT image/x-portable-pixmap>,
 ".pgm"=>#<CHECKING::YOU::OUT image/x-portable-graymap>,
 ".pbm"=>#<CHECKING::YOU::OUT image/x-portable-bitmap>,
 ".pfm"=>#<CHECKING::YOU::OUT application/x-font-type1>,
 ".hdr"=>#<CHECKING::YOU::OUT image/x-hdr>,
 ".dz"=>#<CHECKING::YOU::OUT image/vnd.microsoft.deep-zoom+xml>,
 ".png"=>#<CHECKING::YOU::OUT image/png>,
 ".jpg"=>#<CHECKING::YOU::OUT image/jpeg>,
 ".jpeg"=>#<CHECKING::YOU::OUT image/jpeg>,
 ".jpe"=>#<CHECKING::YOU::OUT image/jpeg>,
 ".webp"=>#<CHECKING::YOU::OUT image/webp>,
 ".tif"=>#<CHECKING::YOU::OUT image/tiff>,
 ".tiff"=>#<CHECKING::YOU::OUT image/tiff>,
 ".fits"=>#<CHECKING::YOU::OUT image/fits>,
 ".fit"=>#<CHECKING::YOU::OUT image/fits>,
 ".fts"=>#<CHECKING::YOU::OUT image/fits>,
 ".gif"=>#<CHECKING::YOU::OUT image/gif>,
 ".bmp"=>#<CHECKING::YOU::OUT image/bmp>}
```

In actual usage we can discard the suffixes and remove any duplicate results:

```
irb> ::Vips::Foreign::suffixes.yield_self(&::CHECKING::YOU::OUT::method(:from_postfix)).uniq
=>
[#<CHECKING::YOU::OUT text/csv>,
 #<CHECKING::YOU::OUT application/x-matlab-data>,
 #<CHECKING::YOU::OUT image/vips>,
 #<CHECKING::YOU::OUT image/x-portable-pixmap>,
 #<CHECKING::YOU::OUT image/x-portable-graymap>,
 #<CHECKING::YOU::OUT image/x-portable-bitmap>,
 #<CHECKING::YOU::OUT application/x-font-type1>,
 #<CHECKING::YOU::OUT image/x-hdr>,
 #<CHECKING::YOU::OUT image/vnd.microsoft.deep-zoom+xml>,
 #<CHECKING::YOU::OUT image/png>,
 #<CHECKING::YOU::OUT image/jpeg>,
 #<CHECKING::YOU::OUT image/webp>,
 #<CHECKING::YOU::OUT image/tiff>,
 #<CHECKING::YOU::OUT image/fits>,
 #<CHECKING::YOU::OUT image/gif>,
 #<CHECKING::YOU::OUT image/bmp>]
```

Boom, now we're defining our Module interface with live Objects instead of with Strings! To make use of this interface all we have to do is perform CYO's matching on an unknown input file and activate this Module iff the result is also in our interface's list of supported types:

```
irb* ::Vips::Foreign::suffixes.yield_self(&::CHECKING::YOU::OUT::method(:from_postfix)).include?(
irb*   ::CHECKING::YOU::OUT('/home/okeeblow/invasion_of_the_gabber_rob.mp3')
irb> )
=> false

irb* ::Vips::Foreign::suffixes.yield_self(&::CHECKING::YOU::OUT::method(:from_postfix)).include?(
irb*   ::CHECKING::YOU::OUT('/home/okeeblow/hello.jpg')
irb> )
=> true
```

## Alternative Ruby Libraries

CYO aims to implement the whole `shared-mime-info` specification and then some, but it is designed around my specific need for a "fast inner loop" of file/stream identification in DistorteD. My needs are not your needs. Please consider if one of these other fine Ruby libraries meets your needs before choosing CHECKING YOU OUT:


- [`ruby-mime-types`](https://github.com/mime-types/ruby-mime-types) and its associated [`mime-types-data`](https://github.com/mime-types/mime-types-data)
were my original choice for DistorteD, and the first version of `CYO` wrapped this library to provide `DD`-specific methods and custom additional type data.
This library determines type based on file extensions (e.g. `hello.jpg` ➔ `[#<MIME::Type: image/jpeg>]`) and does not provide "magic" file-content matching.
Its API [descends from](https://github.com/mime-types/ruby-mime-types/blob/ca89015739efe42e12c279823190dba9bcaaf6b6/History.rdoc#label-1.003)
Mark Overmeer's [`MIME-Types`](http://perl.overmeer.net/CPAN/#MIME-Types) Perl module.
Its type data comes [from Apache HTTPd's Media Type list](https://github.com/mime-types/mime-types-data/blob/master/support/apache_mime_types.rb)
and [from IANA's Media Type registry](https://github.com/mime-types/mime-types-data/blob/master/support/iana_registry.rb) and is usually updated [several times per year](https://github.com/mime-types/mime-types-data/tags).


- [`mimemagicrb`](https://github.com/mimemagicrb/mimemagic) was popular in Rails circles via Rails' wrapper before that wrapper became standalone.
Like CYO, `mimemagicrb` uses `freedesktop.org`'s `shared-mime-info` XML package as a data source.
Unlike CYO, `mimemagicrb` does a one-shot runtime transformation of `freedesktop.org.xml` to load all file extensions and content-matching sequences into memory. That transformation used to happen once at Gem package time with the transformed data shipping as part of the Gem, but it [became a runtime transformation](https://github.com/mimemagicrb/mimemagic/commit/f95088a05bcf07fbad73c350db1e2b9fe4a0441e#diff-fc52eb3b499c02ca79f89e62ac2cc41c160f4759942a36730cb50e89908a5b03)
following a [license-incompatibility issue](https://github.com/mimemagicrb/mimemagic/issues/97) between the freedesktop database's GPLv2 license and `mimemagic`'s MIT license.
The library authors' attempts to clean up the older infringing Gem versions resulted in a
[shameful](https://github.com/mimemagicrb/mimemagic/issues/98)
[outpouring](https://old.reddit.com/r/ruby/comments/mc5bpe/mimemagic_versions_prior_to_036_have_been_yanked/)
[of](https://old.reddit.com/r/ruby/comments/mdriyy/all_versions_of_mimemagic_on_rubygemsorg_are_now/)
[hate](https://github.com/rails/rails/issues/41750) from underprepared members of the Rails “““community””” toward these *volunteers*
in a fantastic display of the same attitudes that kept me away from Ruby entirely for over a decade.
This library now requires a separate upfront installation of `freedesktop.org.xml` in a well-known filesystem location,
usually accomplished by installing `shared-mime-info` via Homebrew or some other package manager.

- [`mini_mime`](https://github.com/discourse/mini_mime) is an alternative representation of [`mime-types-data`](https://github.com/mime-types/mime-types-data) focused on performance via simplicity above all else. It does not load `mime-types-data` at runtime, instead [processing it](https://github.com/discourse/mini_mime/blob/ecaaffd63fe5cc86cdc3cbef42cde0aa81e47832/Rakefile#L34) at Gem package time into flat text files which are then [locked and binary-searched](https://github.com/discourse/mini_mime/blob/63802d1e45cb2b831c34b5d68e364b5ea35c050a/lib/mini_mime.rb#L52-L75) during lookup.

- [`marcel`](https://github.com/rails/marcel/) is Rails' file-typing library, originally a `mimemagicrb` wrapper which
[became standalone](https://github.com/rails/marcel/commit/2e58d1986715420f0abbba060b6e158d6f4d3a05) at the time of the `mimemagicrb` license drama.
This library uses the `shared-mime-info` format but not the usual GPLv2 `freedesktop.org` definition package.
Apache's Tika project supplies [an alternative MIT-licensed XML package](https://gitbox.apache.org/repos/asf?p=tika.git;a=blob;f=tika-core/src/main/resources/org/apache/tika/mime/tika-mimetypes.xml;h=2baa84d0e9c255b45ebb5df0b13c2c782c2cf6ad;hb=HEAD) which Marcel
[transforms to regular Ruby `Hash`es](https://github.com/rails/marcel/blob/main/script/generate_tables.rb)
as part of [its release cycle](https://github.com/rails/marcel/blob/main/Rakefile).

### Feature Matrix

| Match Criteria | CHECKING YOU OUT | [`mime-types`](https://github.com/mime-types/ruby-mime-types) | [`mimemagicrb`](https://github.com/mimemagicrb/mimemagic) | [`mini_mime`](https://github.com/discourse/mini_mime) | [`marcel`](https://github.com/rails/marcel/) |
|---|---|---|---|---|---|
| *Filename extension*               | ☑ | ☑ | ☑ | ☑ | ☑ |
| *Filename pattern*                 | ☑ | ☐ | ☐ | ☐ | ☐ |
| *Stream content*                   | ☑ | ☐ | ☑ | ☐ | ☑ |
| *Non-regular files*                | ☑ | ☐ | ☐ | ☐ | ☐ |
| *Directory tree*                   | ☑ | ☐ | ☐ | ☐ | ☐ |
| *URI scheme*                       | ☑ | ☐ | ☐ | ☐ | ☐ |
| *XML root/namespace*               | ☑ | ☐ | ☐ | ☐ | ☐ |
| *FourCC*                           | ☑ | ☐ | ☐ | ☐ | ☐ |
| *GUID*                             | ☐ | ☐ | ☐ | ☐ | ☐ |
| *UTI*                              | ☐ | ☐ | ☐ | ☐ | ☐ |
| *Extended filesystem attributes*   | ☑ | ☐ | ☐ | ☐ | ☐ |

### Honorable mentions

- [`file`/`libmagic`](http://www.darwinsys.com/file/) interfaces:

    - [`ruby-magic`](https://github.com/kwilczynski/ruby-magic)

    - [`mahoro`](https://yhbt.net/mahoro.git/)

    - [`ruby-filemagic`](https://github.com/blackwinter/ruby-filemagic/) ([unmaintained](https://github.com/blackwinter/ruby-filemagic/commit/e1f2efd07da4130484f06f58fed016d9eddb4818))

    - [`ffiruby-filemagic`](https://github.com/glongman/ffiruby-filemagic/)

- [`shared-mime-info`](https://github.com/hanklords/shared-mime-info) is a Ruby Gem not to be confused with the specification of the same name. Unlike CYO, this library [consumes the `glob`/`magic` files](https://github.com/hanklords/shared-mime-info/blob/7b105f3ed7e8b34f0e14a9d573f4500d85679ca7/lib/shared-mime-info.rb#L300-L306) generated by the [`update-mime-database`](https://cgit.freedesktop.org/xdg/shared-mime-info/tree/src/update-mime-database.c) utility instead of consuming the source XML package files directly.

## GreeTz

- @ohler55 for [`ox`](https://github.com/ohler55/ox), the only Ruby XML library I found that could parse `freedesktop.org.xml` faster than `ruby-mime-types` took to load.
- @dearblue for [`ruby-extattr`](https://github.com/dearblue/ruby-extattr).
- @minad — you did the right thing.
