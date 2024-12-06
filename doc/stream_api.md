This API can operate on an unbuffered (i.e., 'lazy') stream of data. It
simply buffers it into a [kXXH3StreamBufferSize][]-byte buffer and computes
some rounds once the buffer reaches capacity or the final digest call is
made.

This means memory usage should hover around the buffer size - even for huge
(e.g., several gigabytes) payloads!

For small payload sizes (i.e., less than [kXXH3SmallDataSize][]); this method
likely introduces unnecessary overhead in terms of operations and the API so you
would be better off using the buffer API ([xxh3][]) unless you specifically need
the streaming API.

Typical use cases for the streaming API are hashing large files, or working with
data of an unknown size.

[kXXH3StreamBufferSize]: https://pub.dev/documentation/xxh3/latest/xxh3/kXXH3StreamBufferSize-constant.html
[kXXH3SmallDataSize]: https://pub.dev/documentation/xxh3/latest/xxh3/kXXH3SmallDataSize-constant.html
[xxh3]: https://pub.dev/documentation/xxh3/latest/xxh3/xxh3.html
