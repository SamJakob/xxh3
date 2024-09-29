library xxh3;

import 'dart:typed_data';

//
// Buffers
//

/// Reads a 32-bit little-endian integer from the specified buffer at the
/// specified byte offset. (If unspecified, [byteOffset] is 0 which means the
/// value is read from the start of the buffer.)
@pragma('vm:prefer-inline')
int readLE32(ByteData bd, [int byteOffset = 0]) {
  return bd.getUint32(byteOffset, Endian.little);
}

/// Reads a 64-bit little-endian integer from the specified buffer at the
/// specified byte offset. (If unspecified, [byteOffset] is 0 which means the
/// value is read from the start of the buffer.)
@pragma('vm:prefer-inline')
int readLE64(ByteData bd, [int byteOffset = 0]) {
  return bd.getUint64(byteOffset, Endian.little);
}

//
// Math
//

/// Multiplies [lhs] and [rhs], bitwise, then XORs the resulting pair of 64-bit
/// integers (the lower and upper half of the 128-bit output) to 'fold' it back
/// into a 64-bit integer.
@pragma('vm:prefer-inline')
int mul128Fold64(int lhs, int rhs) {
  int loLo = (lhs & 0xFFFFFFFF) * (rhs & 0xFFFFFFFF);
  int hiLo = (lhs >>> 32) * (rhs & 0xFFFFFFFF);
  int loHi = (lhs & 0xFFFFFFFF) * (rhs >>> 32);
  int hiHi = (lhs >>> 32) * (rhs >>> 32);
  int cross = (loLo >>> 32) + (hiLo & 0xFFFFFFFF) + loHi;
  int upper = (hiLo >>> 32) + (cross >>> 32) + hiHi;
  int lower = (cross << 32) | (loLo & 0xFFFFFFFF);
  return lower ^ upper;
}

/// Swaps the byte order of a 32-bit integer.
@pragma('vm:prefer-inline')
int swap32(int x) {
  return ((x << 24) & 0xff000000) |
      ((x << 8) & 0x00ff0000) |
      ((x >>> 8) & 0x0000ff00) |
      ((x >>> 24) & 0x000000ff);
}

/// Swaps the byte order of a 64-bit integer.
@pragma('vm:prefer-inline')
int swap64(int x) {
  return ((x << 56) & 0xff00000000000000) |
      ((x << 40) & 0x00ff000000000000) |
      ((x << 24) & 0x0000ff0000000000) |
      ((x << 8) & 0x000000ff00000000) |
      ((x >>> 8) & 0x00000000ff000000) |
      ((x >>> 24) & 0x0000000000ff0000) |
      ((x >>> 40) & 0x000000000000ff00) |
      ((x >>> 56) & 0x00000000000000ff);
}
