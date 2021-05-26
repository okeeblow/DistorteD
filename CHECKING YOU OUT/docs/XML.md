# Ruby XML Library Decision Zone (2021 edition)

There are a bunch of libraries for XML parsing in Ruby. Which one should I use?

# Use Case

All of the naming here gets kind of confusing, because people tend to use the names of specific old Java XML APIs
as the generic term for the type of parser they represent, e.g. a lot of people say "SAX Parser" to describe
event-based push parsers in general even if they aren't at all similar to the actual SAX.

https://en.wikipedia.org/wiki/Java_API_for_XML_Processing
https://www.xml.com/pub/a/2003/09/17/stax.html
https://royjin.wordpress.com/2010/08/23/java-stax-vs-sax/

Parser classes: tree and event
- Tree
 - DOM, JDOM, dom4j, etc
- Event
 - SAX
 - StAX
 - XMLPULL

"StAX shares with SAX the ability to read arbitrarily large documents.
However, in StAX the application is in control rather than the parser.
The application tells the parser when it wants to receive the next data chunk
rather than the parser telling the client when the next chunk of data is ready.
Furthermore, StAX exceeds SAX by allowing programs to both read existing XML documents
and create new ones. Unlike SAX, StAX is a bidirectional API."

My use-case is probably nonstandard in that I primarily care about un-warmed startup performance
reading a very small set of well-known files, not arbitrarily-complex XML delivered over a network
to a long-lived application instance.

My sweet-spot is somewhere between "as fast as possible when parsing" and "as easy as possible to install",
but there's no single factor that makes me go "Obviously this one!" over all of the others.

I was using Nokogiri but want to avoid the heavy native-compilation step of their bundled `libxml2`.
Pure-Ruby would be ideal, but not at the cost of significant additional startup speed
since DistorteD reads both the upstream and our local `tika-mimetypes` files each time it starts up.


# Considered

REXML — "Ruby Electric XML"
- Built in, and pure-Ruby!
- Code: https://github.com/ruby/rexml/
- Docs: https://ruby-doc.org/stdlib/libdoc/rexml/rdoc/REXML.html
- Tutorial: https://web.archive.org/web/20190206060257/http://www.germane-software.com/software/rexml/docs/tutorial.html
- The only reason I didn't choose this was desire for the fastest possible startup speed.
- Well, and because I can't figure out how to provide a known schema upfront to a StreamReader
 for parsing an XML document that does not include any info about its own custom prefixes (e.g. <tika:whatever/>)
 without REXML's `:parse` method raising a `REXML::UndefinedNamespaceException (Undefined prefix tika: found)`.

Ox — "Optimized XML"
- Has custom (non-libxml/expat) native extension: https://github.com/ohler55/ox/tree/develop/ext/ox
- Announcement: http://www.ohler.com/dev/xml_with_ruby/xml_with_ruby.html
- Code: https://github.com/ohler55/ox
- Dox: http://www.ohler.com/ox/
- Example: https://gist.github.com/tkosaka1976/04929f984cc0e41ca255d127424ebbbd
- Gem: https://rubygems.org/gems/ox
- License: MIT

Oga
- Announcement: https://yorickpeterse.com/articles/oga-a-new-xml-and-html-parser-for-ruby/
- Base parser: https://gitlab.com/yorickpeterse/ruby-ll/
- Has C *and* Java extensions: https://gitlab.com/yorickpeterse/ruby-ll/-/tree/master/ext
- Code: https://gitlab.com/yorickpeterse/oga
- Docs: http://code.yorickpeterse.com/oga/latest/
- Gem: https://rubygems.org/gems/oga
- License: MPL 2.0
- imo has the highest-quality / most-readable code of all of these, and I liked its API the most.

LibXML-Ruby
- Code: https://github.com/xml4r/libxml-ruby
- Docs: https://xml4r.github.io/libxml-ruby/
- Gem: https://rubygems.org/gems/libxml-ruby
- License: MIT
- XSLT add-on: https://github.com/xml4r/libxslt-ruby
- Probably not going to use because it still requires libxml2, but at least it can be a libxml2 from my pkg server.


# Not considered

Nokogiri — Hpricot API compatible (originally) but built on libxml2.
- Moving away from this. This is what I used before investigating these others.
- Popular, and likely to be required by something besides DistorteD anyway if you have a complex app/site.
- Heavy installation with duplicate upstream libs: https://nokogiri.org/tutorials/installing_nokogiri.html
- Criticism from competitor project (2016): https://gitlab.com/yorickpeterse/oga/-/wikis/Problems-with-Nokogiri
- Still has Hpricot API-alike: https://www.rubydoc.info/gems/nokogiri/1.0.6/Nokogiri/Hpricot

Hpricot (defunct) — _why's library, based on htree's code, with JQuery selector support and C-based parser.
- Code: https://github.com/hpricot/hpricot
- _why: https://web.archive.org/web/20081216100009/http://code.whytheluckystiff.net:80/hpricot/
- I guess this is one of the reasons (besides being outed) `_why` quit and Deleted Fucking Everything?
 https://www.ruby-forum.com/t/hpricot-0-7/163149
 https://web.archive.org/web/20090526063501/http://hackety.org/2008/11/03/hpricotStrikesBack.html
 https://viewsourcecode.org/why/twitter/lastTweets.html
 - "caller asks, 'should i use hpricot or nokogiri?' if you’re NOT me: use nokogiri. and if you’re me: well cut it out, stop being me."
 - "programming is rather thankless. you see your works become replaced by superior works in a year. unable to run at all in a few more."
 Obviously not Nokogiri or its authors' """fault""" in any way, but still lmao. So long, and thanks for all the bacon :(

htree
- Code: https://github.com/akr/htree
- Web: http://www.a-k-r.org/htree/

Wrappers:
- https://github.com/mvz/happymapper
- https://github.com/soulcutter/saxerator
- https://github.com/Absolventa/saxophone
- https://github.com/rubymaniac/saxxy
- https://github.com/jonahb/rpath
- https://github.com/cielavenir/multisax


# Benchmarks!

I am intentionally testing un-warmed startup-and-exit performance here since DD's media-type database
will be built from Tika/fd.o XML at every startup.

Control — my previous approach to typing was built around https://github.com/mime-types/ruby-mime-types

[okeeblow@emi#tika-mimetypes] time ruby -r'mime/types' -e 'puts "Loaded #{MIME::Types.to_a.length} types"' -e 'exit'
Loaded 2315 types
ruby -r'mime/types' -e 'puts "Loaded #{MIME::Types.to_a.length} types"' -e   0.12s user 0.04s system 99% cpu 0.162 total
ruby -r'mime/types' -e 'puts "Loaded #{MIME::Types.to_a.length} types"' -e   0.12s user 0.01s system 99% cpu 0.129 total
ruby -r'mime/types' -e 'puts "Loaded #{MIME::Types.to_a.length} types"' -e   0.12s user 0.01s system 99% cpu 0.132 total
ruby -r'mime/types' -e 'puts "Loaded #{MIME::Types.to_a.length} types"' -e   0.12s user 0.01s system 98% cpu 0.127 total
ruby -r'mime/types' -e 'puts "Loaded #{MIME::Types.to_a.length} types"' -e   0.13s user 0.01s system 99% cpu 0.135 total


REXML

[okeeblow@emi#tika-mimetypes] for i in {1..5}; do time ruby -r'rexml/parsers/sax2parser' -r'rexml/sax2listener' \
-e 'class CYO; attr_accessor :ident; def initialize(ident); self.ident = ident; end; end' \
-e 'class TikaPlode; include REXML::SAX2Listener; def loaded; @loaded ||= Array.new; end; ' \
  -e 'def start_element(uri, localname, tag_name, attrs); if tag_name == "mime-type"; @scratch = CYO.new(attrs.fetch("type")); end; end;' \
  -e 'def end_element(uri, localname, tag_name); if tag_name == "mime-type"; self.loaded.append(@scratch); @scratch = nil; end; end; end;' \
-e 'handler = TikaPlode.new; parser = REXML::Parsers::SAX2Parser.new(File.open("tika-mimetypes.xml")); parser.listen(handler); parser.parse' \
-e 'puts "Loaded #{handler.loaded.length} types"' \
-e 'exit'; done
Loaded 1598 types
ruby -r'rexml/parsers/sax2parser' -r'rexml/sax2listener' -e  -e  -e  -e  -e    0.29s user 0.02s system 99% cpu 0.307 total
ruby -r'rexml/parsers/sax2parser' -r'rexml/sax2listener' -e  -e  -e  -e  -e    0.27s user 0.02s system 99% cpu 0.289 total
ruby -r'rexml/parsers/sax2parser' -r'rexml/sax2listener' -e  -e  -e  -e  -e    0.27s user 0.02s system 99% cpu 0.288 total
ruby -r'rexml/parsers/sax2parser' -r'rexml/sax2listener' -e  -e  -e  -e  -e    0.26s user 0.03s system 99% cpu 0.288 total
ruby -r'rexml/parsers/sax2parser' -r'rexml/sax2listener' -e  -e  -e  -e  -e    0.27s user 0.02s system 99% cpu 0.289 total


Oga

[okeeblow@emi#tika-mimetypes] for i in {1..5}; do time ruby -r'oga' \
 -e 'class CYO; attr_accessor :ident; def initialize(ident); self.ident = ident; end; end' \
 -e 'class TikaPlode; def loaded; @loaded ||= Array.new; end; ' \
   -e 'def on_element(namespace, tag_name, attrs = {}); if tag_name == "mime-type"; @scratch = CYO.new(attrs.fetch("type")); end; end;' \
   -e 'def after_element(namespace, tag_name); if tag_name == "mime-type"; self.loaded.append(@scratch); @scratch = nil; end; end; end;' \
 -e 'handler = TikaPlode.new; Oga::XML::SaxParser.new(handler, File.open("tika-mimetypes.xml"), strict: true, html: false).parse' \
 -e 'puts "Loaded #{handler.loaded.length} types"' \
 -e 'exit'; done
Loaded 1598 types
ruby -r'oga' -e  -e  -e  -e  -e  -e  -e 'exit'  0.19s user 0.02s system 99% cpu 0.206 total
ruby -r'oga' -e  -e  -e  -e  -e  -e  -e 'exit'  0.17s user 0.02s system 99% cpu 0.186 total
ruby -r'oga' -e  -e  -e  -e  -e  -e  -e 'exit'  0.18s user 0.01s system 99% cpu 0.188 total
ruby -r'oga' -e  -e  -e  -e  -e  -e  -e 'exit'  0.18s user 0.01s system 99% cpu 0.188 total
ruby -r'oga' -e  -e  -e  -e  -e  -e  -e 'exit'  0.17s user 0.01s system 99% cpu 0.184 total


Ox

[okeeblow@emi#tika-mimetypes] for i in {1..5}; do time ruby -r'ox' \
 -e 'class CYO; attr_accessor :ident; def initialize(ident); self.ident = ident; end; end' \
 -e 'class TikaPlode < Ox::Sax; def loaded; @loaded ||= Array.new; end; ' \
   -e 'def start_element(tag_name); if tag_name == :"mime-type"; @scratch = CYO.new(nil); end; end;' \
   -e 'def attr(name, value); if name == :type; @scratch&.ident = value; end; end;' \
   -e 'def end_element(tag_name); if tag_name == :"mime-type"; self.loaded.append(@scratch); @scratch = nil; end; end; end;' \
 -e 'handler = TikaPlode.new; Ox.sax_parse(handler, File.open("tika-mimetypes.xml"))' \
 -e 'puts "Loaded #{handler.loaded.length} types"' \
 -e 'exit'; done
Loaded 1598 types
ruby -r'ox' -e  -e  -e  -e  -e  -e  -e  -e 'exit'  0.07s user 0.01s system 99% cpu 0.078 total
ruby -r'ox' -e  -e  -e  -e  -e  -e  -e  -e 'exit'  0.07s user 0.00s system 99% cpu 0.065 total
ruby -r'ox' -e  -e  -e  -e  -e  -e  -e  -e 'exit'  0.06s user 0.01s system 99% cpu 0.066 total
ruby -r'ox' -e  -e  -e  -e  -e  -e  -e  -e 'exit'  0.06s user 0.00s system 99% cpu 0.066 total
ruby -r'ox' -e  -e  -e  -e  -e  -e  -e  -e 'exit'  0.06s user 0.01s system 99% cpu 0.071 total


# Decision

I like Oga the most, but Ox seems to have it beat for speed in MRI.
If I wanted to run DistorteD on JRuby I would choose Oga since it has a Java extention as well as C.
For now I only use MRI, so I will use Ox!
Perhaps this is a valid case for optional libraries in DD and perhaps also explains the plethora of wrappers.
