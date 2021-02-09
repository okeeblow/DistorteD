# Cooltrainer::DistorteD

`DistorteD` is a multimedia toolkit for Jekyll websites.

In this repository:
- [`DistorteD-Jekyll`](https://rubygems.org/gems/distorted-jekyll) contains anything and everything that relates to markup generation and Jekyll integration.
- [`DistorteD-Floor`](https://rubygems.org/gems/distorted) — a.k.a. just 'DistorteD' — contains the media format conversion abilities and a CLI to use them.
- [`DistorteD-Booth`](https://rubygems.org/gems/distorted-booth) is a very early proof-of-concept DD GUI that isn't very interesting or useful yet :)

## Motivation

DD is my solution for displaying photos, videos, and other types of media on [cooltrainer.org](https://cooltrainer.org) due to my dissatisfaction with every other solution I could find.

My previous approach was similar to what's [described here](https://eduardoboucas.com/blog/2014/12/07/including-and-managing-images-in-jekyll.html), with small/medium/large image size variations generated with [Jekyll-MiniMagick](https://github.com/MattKevan/Jekyll-MiniMagick-new).

Here are some already-existing ways to put pictures on your Jekyll site that are worth your consideration before choosing DistorteD:

- [jekyll-responsive-image](https://github.com/wildlyinaccurate/jekyll-responsive-image)
- [jekyll_picture_tag](https://rbuchberger.github.io/jekyll_picture_tag/)
- [jekyll-gallery-generator](https://github.com/ggreer/jekyll-gallery-generator)
- [jekyll-photo-gallery](https://github.com/aerobless/jekyll-photo-gallery)
- [jekyll-thumbnail](https://superterran.github.io/jekyll-thumbnail/)
- [jekyll-assets](https://github.com/envygeeks/jekyll-assets)

I wanted a solution that fit all of my preferences:

- I want to write Markdown and stop littering my Markdown files with instances of Liquid tags like `{% my_image_tag some_photo.jpg %}`. Markdown has an image syntax: same as the hyperlink syntax but with a preceding bang (`!`). It seems [generally accepted](https://talk.commonmark.org/t/embedded-audio-and-video/441/15) that this same syntax is used for video as well.
- I want to support many media types (images, videos, PDF, SVG, etc) with the same syntax and workflow on the source side, and with consistent look-and-feel on the output side.
- I want automatic format conversion to maximize compatibility and efficiency, e.g. JPEGs and PNGs should also generate a WebP/AVIF, native WebPs should generate JPEG or PNG for older browsers, single-frame GIFs should generate a PNG/WebP/AVIF, animated GIFs should generate an MPEG-4 (or other format) video, all videos should generate HLS and DASH segments/playlists, etc.
- I want my media files to be able to live in the same directory as their corresponding post/page Markdown. This is something I think Hugo gets right with its concept of [Page Bundles](https://gohugo.io/content-management/page-bundles/). You can get similar functionality with [jekyll-postfiles](https://nhoizey.github.io/jekyll-postfiles/), but it won't generate thumbnails or `<img>`/`<picture>` tags for you. Most Jekyll asset plugins want me to have a single images folder for my entire site.
- I don't want to depend on any APIs, so plugins like [jekyll-cloudinary](https://nhoizey.github.io/jekyll-cloudinary/), [S3_Video](https://gist.github.com/TimShi/a48fa83abbc8a0242557), and [jekyll-imgix](https://docs.imgix.com/libraries/jekyll-imgix) are out.
- I don't want to host my photos on a social network, so [Jekyllgram](https://github.com/benbarber/jekyll-instagram), [jekyll-twitter-plugin](https://github.com/rob-murray/jekyll-twitter-plugin), and [jekyll-google-photos](https://github.com/heychirag/jekyll-google-photos) are out.
- I try to [avoid shelling out](https://julialang.org/blog/2012/03/shelling-out-sucks/) if possible, mostly for the sake of efficiency with very large Jekyll sites so we aren't forking and spawning an entire shell just to call `convert` or `ffmpeg` for every single image in every single page. That means avoiding some popular libraries like [mini_magick](https://github.com/minimagick/minimagick/blob/master/lib/mini_magick/shell.rb) and [streamio-ffmpeg](https://github.com/streamio/streamio-ffmpeg/blob/master/lib/streamio-ffmpeg.rb).
- I want to good defaults handling of things like EXIF tag sanitization, auto-rotation, smart cropping, and chosen formats. Any of these options should be configurable per-instance with a Maruku/Kramdown-style [attribute list](https://golem.ph.utexas.edu/~distler/maruku/proposal.html).


## Installation

Add to your site's Gemfile:

```ruby
group :jekyll_plugins do
  gem 'distorted-jekyll'
  gem 'distorted'
end
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install distorted-jekyll


## Usage Example

No manual usage is necessary! Just write Markdown and use Markdown's image syntax
for photos and videos. DistorteD (by default) uses a `pre_render` hook into
transform instances of Markdown image syntax to instances of DistorteD's Liquid tag.

```
![alt text](some-photo.jpg "title text")
```

e.g. this Markdown:

```
![beatmaniaⅡᴅx turntable mechanism explosion diagram](IIDX-turntable.svg 'Not pictured: your favorite spindle oil.')
```

With this log output:

```
DistorteD::write_image_png IIDX-turntable-fallback.png
DistorteD::write_image_png IIDX-turntable-(333|555|777|1111).png
DistorteD::write_image_webp IIDX-turntable-(333|555|777|1111).webp
DistorteD::write_image_jpeg IIDX-turntable-(333|555|777|1111).jpg
DistorteD::write_image_svg_xml IIDX-turntable.svg
           Writing: /home/okeeblow/Works/DDDemo/_site/jekyll/update/2020/06/17/welcome-to-jekyll.html
```

Generates this HTML:

```
<div class="distorted svg png webp jpeg">
  <a href="/jekyll/update/2020/06/17/IIDX-turntable.svg">
    <picture>
      <source srcset="/jekyll/update/2020/06/17/IIDX-turntable.svg" type="image/svg+xml" />
      <source srcset="/jekyll/update/2020/06/17/IIDX-turntable.webp 595w, /jekyll/update/2020/06/17/IIDX-turntable-333.webp 333w, /jekyll/update/2020/06/17/IIDX-turntable-555.webp 555w, /jekyll/update/2020/06/17/IIDX-turntable-777.webp 777w, /jekyll/update/2020/06/17/IIDX-turntable-1111.webp 1111w" type="image/webp" />
      <source srcset="/jekyll/update/2020/06/17/IIDX-turntable.png 595w, /jekyll/update/2020/06/17/IIDX-turntable-333.png 333w, /jekyll/update/2020/06/17/IIDX-turntable-555.png 555w, /jekyll/update/2020/06/17/IIDX-turntable-777.png 777w, /jekyll/update/2020/06/17/IIDX-turntable-1111.png 1111w" type="image/png" />
      <source srcset="/jekyll/update/2020/06/17/IIDX-turntable.jpg 595w, /jekyll/update/2020/06/17/IIDX-turntable-333.jpg 333w, /jekyll/update/2020/06/17/IIDX-turntable-555.jpg 555w, /jekyll/update/2020/06/17/IIDX-turntable-777.jpg 777w, /jekyll/update/2020/06/17/IIDX-turntable-1111.jpg 1111w" type="image/jpeg" />
      <img src="/jekyll/update/2020/06/17/IIDX-turntable-fallback.png" alt="beatmaniaⅡᴅx turntable mechanism explosion diagram" title="Not pictured: your favorite spindle oil." loading="lazy" />
    </picture>
  </a>
</div>
```


## License

DistorteD is available as open source under the terms of the [GNU Affero General Public License version 3](https://opensource.org/licenses/AGPL-3.0).
