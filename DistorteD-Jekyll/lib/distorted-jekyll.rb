require 'distorted-jekyll/13th-style'
require 'distorted-jekyll/blocks'
require 'distorted-jekyll/md_injection'
require 'distorted-jekyll/invoker'


FATAL_FURY = true
UPDATE_RUBY = "Please use DistorteD with Ruby 2.7.0 or later"
def update_ruby
  if defined? RUBY_PLATFORM
    if (/freebsd/ =~ RUBY_PLATFORM) != nil
      return 'pkg install lang/ruby27'
    elsif (/darwin/ =~ RUBY_PLATFORM) != nil
      return 'brew upgrade ruby'
    elsif (/win/ =~ RUBY_PLATFORM) != nil
      return 'https://rubyinstaller.org/'
    elsif (/linux/ =~ RUBY_PLATFORM) != nil
      if File.exists?('/etc/lsb-release')
        lsb = File.read('/etc/lsb-release')
        if (/Ubuntu|LinuxMint/ =~ lsb) != nil
          return 'https://www.brightbox.com/docs/ruby/ubuntu/#installation'
        end
      end
    end
  end
  return 'https://github.com/rbenv/ruby-build'
end


# I want to be able to use:
# - Array#dig and Hash#dig (Ruby 2.3): https://bugs.ruby-lang.org/issues/11643
# - Lonely operator (Ruby 2.3): https://bugs.ruby-lang.org/issues/11537
# - Hash#transform_keys (Ruby 2.5): https://bugs.ruby-lang.org/issues/13583
# - Enumerable#filter_map (Ruby 2.7): https://bugs.ruby-lang.org/issues/5663
#     https://blog.saeloun.com/2019/05/25/ruby-2-7-enumerable-filter-map.html
# - 'Real' kwargs in preparation for Ruby 3: https://bugs.ruby-lang.org/issues/14183
#     https://www.ruby-lang.org/en/news/2019/12/12/separation-of-positional-and-keyword-arguments-in-ruby-3-0/
if [
  Hash.method_defined?(:dig),  # 2.3
  Hash.method_defined?(:transform_keys),  # 2.5
  Enumerable.method_defined?(:filter_map),  # 2.7
].all?
  # Monkey-patch Jekyll::Cleaner to not nuke DistorteD-generated variations
  # for our media files. This makes DistorteD fast!
  require 'distorted-jekyll/monkey_business/jekyll/cleaner'

  # Register DistorteD's entrypoint class with Liquid.
  # `Invoker` will mix in the proper handler module for the given media.
  Liquid::Template.register_tag('distorted', Jekyll::DistorteD::Invoker)

  # Register a block version for arranging multiple pieces of media.
  Liquid::Template.register_tag('distort', Jekyll::DistorteD::BLOCKS)

  # Register a tag for basic DistorteD CSS.
  Liquid::Template.register_tag('13th_style', Jekyll::DistorteD::ThirteenthStyle)

  # Transform Markdown image syntax ![alt](url.jpg "title")
  # to instances of our liquid tag {% distorted %}
  # Available hooks can be seen here:
  #   https://github.com/jekyll/jekyll/blob/master/lib/jekyll/hooks.rb
  # `:documents` is `:posts`-plus-files-in-collections.
  Jekyll::Hooks.register(:pages, :pre_render, &md_injection)
  Jekyll::Hooks.register(:documents, :pre_render, &md_injection)

else
  # Example of how this looks with the outdated Ruby 2.5 on my Mint 19 laptop:
  #
  # Bundler::GemRequireError: There was an error while trying to load the gem 'distorted-jekyll'.
  # Gem Load Error is: Please use DistorteD with Ruby 2.7.0 or later: https://www.brightbox.com/docs/ruby/ubuntu/#installation
  if FATAL_FURY
    raise RuntimeError.new("#{UPDATE_RUBY}: #{update_ruby}")
  else
    Jekyll.logger.info('DistorteD', "#{UPDATE_RUBY}: #{update_ruby}")
  end
end
