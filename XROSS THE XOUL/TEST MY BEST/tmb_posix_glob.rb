require('bundler/setup')
require('test/unit') unless defined?(::Test::Unit)
require_relative('../lib/xross-the-xoul/posix/glob') unless defined?(::XROSS::THE::POSIX::Glob)

class TestXrossPOSIXglob < ::Test::Unit::TestCase


  # Test cases from MRI Ruby `::File::fnmatch`:
  # https://github.com/ruby/ruby/blob/d92f09a5eea009fa28cd046e9d0eb698e3d94c5c/test/ruby/test_fnmatch.rb#L14-L21
  def test_glob_to_regexp_mri_fnmatch_fnmatch
    # RE: http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-dev/22819
    assert_match(::XROSS::THE::POSIX::Glob::to_regexp('\[1\]'), '[1]')
    # RE: http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-dev/22815
    assert_match(::XROSS::THE::POSIX::Glob::to_regexp('*?'), 'a')

    assert_match(::XROSS::THE::POSIX::Glob::to_regexp('*/'), 'a/')
    # TODO: Do something with `FNM_PATHNAME`
    #assert_match(::XROSS::THE::POSIX::Glob::to_regexp('\[1\]', ::File::FNM_PATHNAME), '[1]')
    #assert_match(::XROSS::THE::POSIX::Glob::to_regexp('*?', ::File::FNM_PATHNAME), 'a')
    #assert_match(::XROSS::THE::POSIX::Glob::to_regexp('*/', ::File::FNM_PATHNAME), 'a/')
  end


  # "Text" test cases from MRI Ruby `::File::fnmatch`:
  # https://github.com/ruby/ruby/blob/d92f09a5eea009fa28cd046e9d0eb698e3d94c5c/test/ruby/test_fnmatch.rb#L23-L28
  def test_glob_to_regexp_mri_fnmatch_text
    # This is testing our end-of-`::String` Anchor.
    assert_match(::XROSS::THE::POSIX::Glob::to_regexp('cat'), 'cat')
    assert_not_match(::XROSS::THE::POSIX::Glob::to_regexp('cat'), 'category')
    assert_not_match(::XROSS::THE::POSIX::Glob::to_regexp('cat'), 'wildcat')
  end


  # "Any one" (as in '?') test cases from MRI Ruby `::File::fnmatch`:
  # https://github.com/ruby/ruby/blob/d92f09a5eea009fa28cd046e9d0eb698e3d94c5c/test/ruby/test_fnmatch.rb#L30-L39
  def test_glob_to_regexp_mri_fnmatch_any_one
    # '?' matches any one character.
    assert_match(::XROSS::THE::POSIX::Glob::to_regexp('?at'), 'cat')
    assert_match(::XROSS::THE::POSIX::Glob::to_regexp('c?t'), 'cat')
    assert_match(::XROSS::THE::POSIX::Glob::to_regexp('ca?'), 'cat')
    assert_match(::XROSS::THE::POSIX::Glob::to_regexp('?a?'), 'cat')
    assert_not_match(::XROSS::THE::POSIX::Glob::to_regexp('c??t'), 'cat')
    assert_not_match(::XROSS::THE::POSIX::Glob::to_regexp('??at'), 'cat')
    assert_not_match(::XROSS::THE::POSIX::Glob::to_regexp('ca??'), 'cat')
  end


  # "Any chars" (as in '*' expansion) test cases from MRI Ruby `::File::fnmatch`:
  # https://github.com/ruby/ruby/blob/d92f09a5eea009fa28cd046e9d0eb698e3d94c5c/test/ruby/test_fnmatch.rb#L41-L53
  def test_glob_to_regexp_mri_fnmatch_any_chars
    # '*' matches any number (including 0) of any characters.
    assert_match(::XROSS::THE::POSIX::Glob::to_regexp('c*'), 'cats')
    assert_match(::XROSS::THE::POSIX::Glob::to_regexp('c*ts'), 'cats')
    assert_match(::XROSS::THE::POSIX::Glob::to_regexp('*ts'), 'cats')
    assert_match(::XROSS::THE::POSIX::Glob::to_regexp('*c*a*t*s'), 'cats')
    assert_not_match(::XROSS::THE::POSIX::Glob::to_regexp('c*t'), 'cats')
    assert_not_match(::XROSS::THE::POSIX::Glob::to_regexp('*abc'), 'abcabz')
    assert_match(::XROSS::THE::POSIX::Glob::to_regexp('*abz'), 'abcabz')
    assert_not_match(::XROSS::THE::POSIX::Glob::to_regexp('a*abc'), 'abc')
    assert_match(::XROSS::THE::POSIX::Glob::to_regexp('a*bc'), 'abc')
    assert_not_match(::XROSS::THE::POSIX::Glob::to_regexp('a*bc'), 'abcd')
  end


  # "Escape" (as in '\') test cases from MRI Ruby `::File::fnmatch`:
  # https://github.com/ruby/ruby/blob/d92f09a5eea009fa28cd046e9d0eb698e3d94c5c/test/ruby/test_fnmatch.rb#L61-L78
  def test_glob_to_regexp_mri_fnmatch_escape
    assert_match(::XROSS::THE::POSIX::Glob::to_regexp('\?'), '?')
    assert_not_match(::XROSS::THE::POSIX::Glob::to_regexp('\?'), '\?')
    assert_not_match(::XROSS::THE::POSIX::Glob::to_regexp('\?'), 'a')
    assert_not_match(::XROSS::THE::POSIX::Glob::to_regexp('\?'), '\a')
    assert_match(::XROSS::THE::POSIX::Glob::to_regexp('\*'), '*')
    assert_not_match(::XROSS::THE::POSIX::Glob::to_regexp('\*'), '\*')
    assert_not_match(::XROSS::THE::POSIX::Glob::to_regexp('\*'), 'cats')
    assert_not_match(::XROSS::THE::POSIX::Glob::to_regexp('\*'), '\cats')
    assert_match(::XROSS::THE::POSIX::Glob::to_regexp('\a'), 'a')
    assert_not_match(::XROSS::THE::POSIX::Glob::to_regexp('\a'), '\a')
    assert_match(::XROSS::THE::POSIX::Glob::to_regexp('[a\-c]'), 'a')
    assert_match(::XROSS::THE::POSIX::Glob::to_regexp('[a\-c]'), '-')
    assert_match(::XROSS::THE::POSIX::Glob::to_regexp('[a\-c]'), 'c')
    assert_not_match(::XROSS::THE::POSIX::Glob::to_regexp('[a\-c]'), 'b')
    assert_not_match(::XROSS::THE::POSIX::Glob::to_regexp('[a\-c]'), '\\')
  end


  # Tests from Python's equivalent Glob-to-Regexp feature, `fnmatch.translate`:
  # https://github.com/python/cpython/blob/b1b4c790e7d3b5f4244450aefe3d8f01710c13f7/Lib/test/test_fnmatch.py#L108-L145
  def test_glob_to_regexp_cpython_fnmatch_translate
    # NOTE: The target `::Regexp` patterns from the Python tests don't have the beginning-of-`::String` (`\A`) Anchor,
    #       but they do have the end-of-`::String` (`\Z`) Anchor. I've modified them here accordingly.
    assert_equal(/\A.*\Z/,       ::XROSS::THE::POSIX::Glob::to_regexp('*'))
    assert_equal(/\A.\Z/,        ::XROSS::THE::POSIX::Glob::to_regexp('?'))
    assert_equal(/\Aa.b.*\Z/,    ::XROSS::THE::POSIX::Glob::to_regexp('a?b*'))
    assert_equal(/\A[abc]\Z/,    ::XROSS::THE::POSIX::Glob::to_regexp('[abc]'))
    assert_equal(/\A[\]]\Z/,     ::XROSS::THE::POSIX::Glob::to_regexp('[]]'))
    assert_equal(/\A[^x]\Z/,     ::XROSS::THE::POSIX::Glob::to_regexp('[!x]'))
    assert_equal(/\A[\^x]\Z/,    ::XROSS::THE::POSIX::Glob::to_regexp('[^x]'))
    assert_equal(/\A\[x\Z/,      ::XROSS::THE::POSIX::Glob::to_regexp('[x'))

    assert_equal(/\A.*\.txt\Z/,  ::XROSS::THE::POSIX::Glob::to_regexp('*.txt'))

    assert_equal(/\A.*\Z/,       ::XROSS::THE::POSIX::Glob::to_regexp('*********'))
    assert_equal(/\AA.*\Z/,      ::XROSS::THE::POSIX::Glob::to_regexp('A*********'))
    assert_equal(/\A.*A\Z/,      ::XROSS::THE::POSIX::Glob::to_regexp('*********A'))
    assert_equal(/\AA.*.[?].\Z/, ::XROSS::THE::POSIX::Glob::to_regexp('A*********?[?]?'))

    fatre = ::Regexp::union(
      ::XROSS::THE::POSIX::Glob::to_regexp('**a**a**a*'),
      ::XROSS::THE::POSIX::Glob::to_regexp('**b**b**b*'),
      ::XROSS::THE::POSIX::Glob::to_regexp('*c*c*c*'),
    )
    assert_match(fatre, 'abaccad')
    assert_match(fatre, 'abxbcab')
    assert_match(fatre, 'cbabcaxc')
    assert_not_match(fatre, 'dabccbad')
  end


  # Tests from Python's basic `fnmatch`, reproduced here just for additional coverage :)
  # https://github.com/python/cpython/blob/b1b4c790e7d3b5f4244450aefe3d8f01710c13f7/Lib/test/test_fnmatch.py#L21-L46
  def test_glob_to_regexp_cpython_fnmatch
    assert_match(::XROSS::THE::POSIX::Glob::to_regexp('abc'), 'abc')
    assert_match(::XROSS::THE::POSIX::Glob::to_regexp('?*?'), 'abc')
    assert_match(::XROSS::THE::POSIX::Glob::to_regexp('???*'), 'abc')
    assert_match(::XROSS::THE::POSIX::Glob::to_regexp('*???'), 'abc')
    assert_match(::XROSS::THE::POSIX::Glob::to_regexp('*'), 'abc')
    assert_match(::XROSS::THE::POSIX::Glob::to_regexp('ab[cd]'), 'abc')
    assert_match(::XROSS::THE::POSIX::Glob::to_regexp('ab[!de]'), 'abc')
    assert_not_match(::XROSS::THE::POSIX::Glob::to_regexp('ab[de]'), 'abc')
    assert_not_match(::XROSS::THE::POSIX::Glob::to_regexp('??'), 'a')
    assert_not_match(::XROSS::THE::POSIX::Glob::to_regexp('b'), 'a')

    assert_match(::XROSS::THE::POSIX::Glob::to_regexp('[\]'), '\\')
    assert_match(::XROSS::THE::POSIX::Glob::to_regexp('[!\]'), 'a')
    assert_not_match(::XROSS::THE::POSIX::Glob::to_regexp('[!\]'), '\\')

    assert_match(::XROSS::THE::POSIX::Glob::to_regexp('foo*'), 'foo\nbar')
    assert_match(::XROSS::THE::POSIX::Glob::to_regexp('foo*'), 'foo\nbar\n')
    #assert_not_match(::XROSS::THE::POSIX::Glob::to_regexp('foo*'), '\nfoo')
    assert_match(::XROSS::THE::POSIX::Glob::to_regexp('*'), '\n')
  end

  # Test possible exponential expansion DoS à la https://bugs.python.org/issue40480
  # TODO: Fix this.
  def test_glob_to_regexp_cpython_slow_fnmatch
    assert_match(::XROSS::THE::POSIX::Glob::to_regexp('*a*a*a*a*a*a*a*a*a*a'), 'a' * 50)
    #assert_not_match(::XROSS::THE::POSIX::Glob::to_regexp('*a*a*a*a*a*a*a*a*a*a'), ('a' * 50).insert(-1, ?b))
  end


end
