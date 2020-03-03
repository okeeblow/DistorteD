# Cooltrainer::DistorteD

`DistorteD` is a multimedia processing tag plugin for Jekyll.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'distorted'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install distorted

## Usage

Use DistorteD to generate web-ready variations for multimedia in any Jekyll post or page.

DistorteD by default uses a `pre_render` hook to transform instances of Markdown
image syntax in your site to instances of DistorteD's Liquid tag.

```
![alt text](some-photo.jpg "title text")
```

e.g.
```
!["beatmania IIDX WavePass card readers being removed from shipping box."](IIDX-Readers-Unboxing.jpg "Including that authentic game center cigarette smell."]

Two or more adjacent lines containing a Markdown image/video inside a Markdown
list item will be combined into a DistorteD grid where the images or videos
will group and flow together in one block on the page, like a tweet.

```
- ![Wavepass card reader installed on my IIDX machine](IIDX-Readers-Installed.jpg "Number one")
- ![IIDX PC parts](IIDX-PC-Parts.jpg "Twoooo")
- ![Adjusting monitor height](IIDX-Raising-Monitor.jpg "Three.")
- ![Card reader enclosures unlocked and hanging open](IIDX-Readers-Unlocked.jpg "Four!")
```

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

## Development

Clone the DistorteD repository and modify your Jekyll `Gemfile` to refer to your local path instead of to the newest published version of the gem:

```
gem 'distorted', :path => '~/Works/DistorteD/', :branch => 'NEW-SENSATION'
```

## License

The gem is available as open source under the terms of the [GNU General Public License version 3](https://opensource.org/licenses/GPL-3.0).
