# Jekyll::DistorteD

`DistorteD-Jekyll` is a multimedia framework for Jekyll websites.

## Motivation

DistorteD is my solution for displaying photos, videos, and other types of media on [cooltrainer.org](https://cooltrainer.org) due to my dissatisfaction with every other solution I could find.

My previous approach was similar to what's [described here](https://eduardoboucas.com/blog/2014/12/07/including-and-managing-images-in-jekyll.html), with small/medium/large image size variations generated with [Jekyll-MiniMagick](https://github.com/MattKevan/Jekyll-MiniMagick-new).

Here are some already-existing ways to put pictures on your Jekyll site that are worth your consideration before choosing DistorteD:

- Octopress' [image_tag](https://github.com/imathis/octopress/blob/master/plugins/image_tag.rb) plugin.
- [jekyll-responsive-image](https://github.com/wildlyinaccurate/jekyll-responsive-image)
- [jekyll_picture_tag](https://rbuchberger.github.io/jekyll_picture_tag/)
- [jekyll-gallery-generator](https://github.com/ggreer/jekyll-gallery-generator)
- [jekyll-photo-gallery](https://github.com/aerobless/jekyll-photo-gallery)
- [jekyll-thumbnail](https://superterran.github.io/jekyll-thumbnail/)
- [jekyll-assets](https://github.com/envygeeks/jekyll-assets)

I wanted a solution that fit all of my preferences:

- I want to write Markdown and stop littering my Markdown files with instances of Liquid tags like `{% my_image_tag some_photo.jpg %}`. Markdown has an image syntax: same as the hyperlink syntax but with a preceding bang (`!`). It seems [generally accepted](https://talk.commonmark.org/t/embedded-audio-and-video/441/15) that this same syntax is used for video as well.
- I try to [avoid shelling out](https://julialang.org/blog/2012/03/shelling-out-sucks/) if possible, mostly for the sake of efficiency with very large Jekyll sites so we aren't forking and spawning an entire shell just to call `convert` or `ffmpeg` for every single image in every single page. That means avoiding some popular libraries like [mini_magick](https://github.com/minimagick/minimagick/blob/master/lib/mini_magick/shell.rb) and [streamio-ffmpeg](https://github.com/streamio/streamio-ffmpeg/blob/master/lib/streamio-ffmpeg.rb).
- I want to support many media types (images, videos, PDF, SVG, etc) with the same syntax and workflow on the source side, and with consistent look-and-feel on the output side.
- I want my media files to be able to live in the same directory as their corresponding post/page Markdown. This is something I think Hugo gets right with its concept of [Page Bundles](https://gohugo.io/content-management/page-bundles/). You can get similar functionality with [jekyll-postfiles](https://nhoizey.github.io/jekyll-postfiles/), but it won't generate thumbnails or `<img>`/`<picture>` tags for you. Most Jekyll asset plugins want me to have a single images folder for my entire site.
- I don't want to depend on any APIs, so plugins like [jekyll-cloudinary](https://nhoizey.github.io/jekyll-cloudinary/), [S3_Video](https://gist.github.com/TimShi/a48fa83abbc8a0242557), and [jekyll-imgix](https://docs.imgix.com/libraries/jekyll-imgix) are out.
- I want automatic format conversion to maximize compatibility and efficiency, e.g. JPEGs and PNGs should also generate a WebP, native WebPs should generate JPEG or PNG for older browsers, single-frame GIFs should generate a PNG/WebP, animated GIFs should generate an MPEG-4 (or other format) video, all videos should generate HLS and DASH segments/playlists, etc.
- I want to good defaults handling of things like EXIF tag sanitization, auto-rotation, smart cropping, and chosen formats. Any of these options should be configurable per-instance with a Maruku/Kramdown-style [attribute list](https://golem.ph.utexas.edu/~distler/maruku/proposal.html).

## Status

Images are fairly well supported and are enabled by default. Video support is very experimental and fragile and is not enabled in the default config. HLS works fine right now with iOS/Safari/Edge, but my current Gst pipeline is very specific to my hardware. I'm waiting on a version of GStreamer to include the new [dashsink2](https://gitlab.freedesktop.org/gstreamer/gst-plugins-bad/merge_requests/704) before I do the work to rewrite my basic `gst_parse`-based pipeline and get it into a usable state for Firefox/Chrome. All other media types are still conceptual. Please don't ask me for ETAs :)

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

## Usage

No manual usage is necessary! Just write Markdown and use Markdown's image syntax
for photos and videos. DistorteD (by default) uses a `pre_render` hook to
transform instances of Markdown image syntax to instances of DistorteD's
Liquid tag.

```
![alt text](some-photo.jpg "title text")
```

e.g.

```
!["beatmania IIDX WavePass card readers being removed from shipping box."](IIDX-Readers-Unboxing.jpg "Including that authentic game center cigarette smell."]
```

Two or more adjacent lines containing a Markdown image/video inside a Markdown
list item will be combined into a DistorteD Block where the images or videos
will group and flow together in one block on the page, like a tweet.

```
‑ ![Wavepass card reader installed on my IIDX machine](IIDX-Readers-Installed.jpg "Number one")
‑ ![IIDX PC parts](IIDX-PC-Parts.jpg "Twoooo")
‑ ![Adjusting monitor height](IIDX-Raising-Monitor.jpg "Three.")
‑ ![Card reader enclosures unlocked and hanging open](IIDX-Readers-Unlocked.jpg "Four!")
```
## Manual Usage

You can also invoke DD's Liquid tag directly. This is the syntax the above Markdown
will be transformed into.

```
{% distorted 
  IIDX-Readers-Unboxing.jpg
  href="original"
  alt="Wavepass card reader hardware being removed from a shipping box"
  title="Complete with that fresh Game Center cigarette smell."
%}
```

or, for a DD grid:

```
{% distort %}
  {% distorted […] %}
  {% distorted […] %}
  {% distorted […] %}
  {% distorted […] %}
{% enddistort %}
```

## Example

Here's an example of embedding an example image in a Jekyll demo site's first post. No site configuration was changed aside from installing the Gem.

The Markdown:

```
![DistorteD logo](DistorteD.png 'This is so cool')
```

The log output:

```
 DistorteD Writing: /home/okeeblow/Works/DDDemo/jekyll/update/2020/06/17/DistorteD-full.png
 DistorteD Writing: /home/okeeblow/Works/DDDemo/jekyll/update/2020/06/17/DistorteD-small.png
 DistorteD Writing: /home/okeeblow/Works/DDDemo/jekyll/update/2020/06/17/DistorteD-medium.png
 DistorteD Writing: /home/okeeblow/Works/DDDemo/jekyll/update/2020/06/17/DistorteD-large.png
 DistorteD Writing: /home/okeeblow/Works/DDDemo/jekyll/update/2020/06/17/DistorteD-full.webp
 DistorteD Writing: /home/okeeblow/Works/DDDemo/jekyll/update/2020/06/17/DistorteD-small.webp
 DistorteD Writing: /home/okeeblow/Works/DDDemo/jekyll/update/2020/06/17/DistorteD-medium.webp
 DistorteD Writing: /home/okeeblow/Works/DDDemo/jekyll/update/2020/06/17/DistorteD-large.webp
           Writing: /home/okeeblow/Works/DDDemo/_site/jekyll/update/2020/06/17/welcome-to-jekyll.html
```

And the actual template output that ends up in the final page:

```
<div class="distorted">
  <a href="/jekyll/update/2020/06/17/DistorteD.png" target="_blank">
    <picture>
      <source srcset="/jekyll/update/2020/06/17/DistorteD-full.png" />
      <source srcset="/jekyll/update/2020/06/17/DistorteD-small.png" media="(max-width: 400px)" />
      <source srcset="/jekyll/update/2020/06/17/DistorteD-medium.png" media="(min-width: 800px)" />
      <source srcset="/jekyll/update/2020/06/17/DistorteD-large.png" media="(min-width: 1500px)" />
      <source srcset="/jekyll/update/2020/06/17/DistorteD-full.webp" />
      <source srcset="/jekyll/update/2020/06/17/DistorteD-small.webp" media="(max-width: 400px)" />
      <source srcset="/jekyll/update/2020/06/17/DistorteD-medium.webp" media="(min-width: 800px)" />
      <source srcset="/jekyll/update/2020/06/17/DistorteD-large.webp" media="(min-width: 1500px)" />
      <img src="/jekyll/update/2020/06/17/DistorteD.png" alt="DistorteD logo" title="This is so cool" loading="eager" />
    </picture>
  </a>
  <span style="clear: left;"></span>
</div>
```

## Development

Clone the DistorteD repository and modify your Jekyll `Gemfile` to refer to your local path instead of to the newest published version of the gem:

```
gem 'distorted-jekyll', :path => '~/repos/DistorteD/DistorteD-Jekyll/'[, :branch => 'NEW-SENSATION']
```

The `DistorteD-Jekyll` Gem will automatically use its local sibling `DistorteD-Core` Gem if used in this way.

## License

The gem is available as open source under the terms of the [GNU Affero General Public License version 3](https://opensource.org/licenses/AGPL-3.0).
