import 'package:xxh3/xxh3.dart';

/// The absolute minimum size for a custom secret as defined in XXH3.
/// See https://github.com/Cyan4973/xxHash/blob/b1a61dff654af43552b5ee05c737b6fd2a0ee14b/xxhash.h#L931
///
/// {@category Buffer API}
/// {@category Stream API}
const kSecretSizeMin = 136;

/// The maximum size, in bytes, of a 'short' key. This is known internally to
/// XXH3 as the 'mid-size max'.
///
/// This constant is exposed publicly to allow for implementations to optimize
/// (primarily) use of the buffer API ([xxh3]) around the 'small' data size.
///
/// {@category Buffer API}
/// {@category Stream API}
const int kXXH3SmallDataSize = 240;

/// The optimal update size for incremental hashing. This size is used in the
/// internal [XXH3State] when calling [XXH3State.update].
///
/// This constant is exposed publicly to allow for implementations to optimize
/// use of the stream API ([xxh3Stream]) around the optimum buffer size.
///
/// {@category Stream API}
const int kXXH3StreamBufferSize = 256;

/// The 32-bit XXH variant prime 1: 0b10011110001101110111100110110001
/// (this prime is used by XXH3).
const int kXXHPrime32_1 = 0x9E3779B1;

/// The 32-bit XXH variant prime 2: 0b10000101111010111100101001110111
/// (this prime is used by XXH3).
const int kXXHPrime32_2 = 0x85EBCA77;

/// The 32-bit XXH variant prime 3: 0b11000010101100101010111000111101
/// (this prime is used by XXH3).
const int kXXHPrime32_3 = 0xC2B2AE3D;

/// The 64-bit XXH variant prime 1:
/// 0b1001111000110111011110011011000110000101111010111100101010000111
/// (this prime is used by XXH3).
const int kXXHPrime64_1 = 0x9E3779B185EBCA87;

/// The 64-bit XXH variant prime 2:
/// 0b1100001010110010101011100011110100100111110101001110101101001111
/// (this prime is used by XXH3).
const int kXXHPrime64_2 = 0xC2B2AE3D27D4EB4F;

/// The 64-bit XXH variant prime 3:
/// 0b0001011001010110011001111011000110011110001101110111100111111001
/// (this prime is used by XXH3).
const int kXXHPrime64_3 = 0x165667B19E3779F9;

/// The 64-bit XXH variant prime 4:
/// 0b1000010111101011110010100111011111000010101100101010111001100011
/// (this prime is used by XXH3).
const int kXXHPrime64_4 = 0x85EBCA77C2B2AE63;

/// The 64-bit XXH variant prime 5:
/// 0b0010011111010100111010110010111100010110010101100110011111000101
/// (this prime is used by XXH3).
const int kXXHPrime64_5 = 0x27D4EB2F165667C5;

/// The length of a stripe, in bytes.
const int kStripeLength = 64;

/// The number of secret bytes consumed at each accumulation.
const int kSecretConsumeRate = 8;

/// The number of blocks that the accumulator requires.
const int kAccNB = 8; // = kStripeLength ~/ sizeof(uint64_t)

/// The number of stripes that can be generated from the [XXH3State] buffer.
const kXXH3BufferStripes = kXXH3StreamBufferSize ~/ kStripeLength;
