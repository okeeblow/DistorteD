require 'mime/types'

# MIME::Types#preferred_extension returns @extensions.first unless
# otherwise set. I don't like some of the defaults, so this file
# changes them.
# Normally I don't like to monkey patch just on import without calling
# some method, but this is one time I explicitly want to do that.
MIME::Types['image/jpeg'].last.preferred_extension = 'jpg'
