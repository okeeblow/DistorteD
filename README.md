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

Use the `{% distorted %}` tag to generate web-ready variations for multimedia in any Jekyll post or page.

```
{% distorted 
  IIDX-Readers-Unboxing.jpg
  href="original"
  alt="Wavepass card reader hardware being removed from a shipping box"
  title="Complete with that fresh Game Center cigarette smell."
%}
```

## Development

Clone the DistorteD repository and modify your Jekyll `Gemfile` to refer to your local path instead of to the newest published version of the gem:

```
gem 'distorted', :path => '~/Works/DistorteD/', :branch => 'NEW-SENSATION'
```

## License

The gem is available as open source under the terms of the [GNU General Public License version 3](https://opensource.org/licenses/GPL-3.0).
