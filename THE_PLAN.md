The plan keeps coming up again,
and the plan means nothing stays the same,
but the plan won't accomplish anything
if it's not implemented 𝅘𝅥𝅮


# Currently Thinking About…


## Specifics

- TESTS TESTS TESTS — TDD sucks but that doesn't mean no tests ever.
- Rename contentious-old-default-Git-branch to something less bad once I can get down to zero local changes.
- Support operating on a single member of multi-stream files like Zip archives or Mac Resources
  - Glue FourCC support on to MIME::Types


## Generics

- Optimize for startup performance
  - Avoid as much filesystem interaction as possible, [even `stat`ing files](https://old.reddit.com/r/ruby/comments/aqxepw/rubys_startup_time_seems_to_get_worse/)!
  - [Prefer `require_relative`](https://bugs.ruby-lang.org/issues/12973) for same reason as above.
  - Avoid `require`ing dependencies up front if possible, e.g. GStreamer is very slow
    but doesn't need to be loaded unless we are working with audio/video.
- Remove/avoid dependencies with native-OS library/environment requirements where possible,
  e.g. for something like filemagic where the library functionality is a means to an end
  but not for something like VIPS where the library is the draw because it's so good.
