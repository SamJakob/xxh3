library xxh3;

import 'dart:typed_data';

import 'package:xxh3/src/xxh3.dart';
import 'package:xxh3/xxh3.dart';

//
// Helpers
//

/// Create an XXH3 accumulator.
@pragma('vm:prefer-inline')
Uint64List createAccumulator() {
  final acc = Uint64List(8);
  resetAccumulator(acc);
  return acc;
}

/// Reset an accumulator created by [createAccumulator].
@pragma('vm:prefer-inline')
void resetAccumulator(Uint64List acc) {
  acc[0] = kXXHPrime32_3;
  acc[1] = kXXHPrime64_1;
  acc[2] = kXXHPrime64_2;
  acc[3] = kXXHPrime64_3;
  acc[4] = kXXHPrime64_4;
  acc[5] = kXXHPrime32_2;
  acc[6] = kXXHPrime64_5;
  acc[7] = kXXHPrime32_1;
}

/// Scramble an accumulator created by [createAccumulator] with the given
/// [secret].
@pragma('vm:prefer-inline')
void scrambleAccumulator(Uint64List acc, ByteData secret,
    {int secretOffset = 0}) {
  for (int i = 0; i < kAccNB; i++) {
    final accI = acc[i];
    acc[i] = (accI ^
            (accI >>> 47) ^
            readLE64(
              secret,
              (secret.lengthInBytes - kStripeLength + 8 * i) + secretOffset,
            )) *
        kXXHPrime32_1;
  }
}

/// Dart implementation of the xxh3_accumulate_512 function from XXH3.
@pragma('vm:prefer-inline')
void accumulate512(Uint64List acc, ByteData input, ByteData secret,
    {int inputOffset = 0, int secretOffset = 0}) {
  int dataVal, dataKey;
  for (int i = 0; i < kAccNB; i++) {
    final nextIndex = i * 8;
    dataVal = readLE64(input, inputOffset + nextIndex);
    dataKey = dataVal ^ readLE64(secret, secretOffset + nextIndex);

    acc[i ^ 1] += dataVal;
    acc[i] += (dataKey & 0xFFFFFFFF) * (dataKey >>> 32);
  }
}

/// Dart equivalent of the xxh3_accumulate function from XXH3. This function
/// performs [accumulate512] for each of the [stripes].
@pragma('vm:prefer-inline')
void accumulate(Uint64List acc, ByteData input, ByteData secret,
    {int inputOffset = 0, int secretOffset = 0, required int stripes}) {
  for (int i = 0; i < stripes; i++) {
    accumulate512(
      acc,
      input,
      secret,
      inputOffset: (i * kStripeLength) + inputOffset,
      secretOffset: (i * kSecretConsumeRate) + secretOffset,
    );
  }
}

/// Dart implementation of the xxh3_avalanche.
/// A fast avalanche stage for when input bits have been already partially
/// mixed.
@pragma('vm:prefer-inline')
int xXH3Avalanche(int h) {
  h ^= h >>> 37;
  h *= 0x165667919E3779F9;
  return h ^ (h >>> 32);
}

/// Validates that the secret is at least [kSecretSizeMin] bytes. If it isn't,
/// throws an [ArgumentError.value]. This function is reused to ensure the error
/// is consistent.
@pragma('vm:prefer-inline')
void validateSecret(TypedData secret) {
  if (secret.lengthInBytes < kSecretSizeMin) {
    throw ArgumentError.value(
      secret,
      'secret',
      "The specified secret is too short. It must be at least $kSecretSizeMin bytes.",
    );
  }
}

@pragma('vm:prefer-inline')
ByteData initCustomSecret(int seed) {
  final seededSecret = ByteData.view(Uint8List(kSecretSize).buffer);

  for (int i = 0; i < kSecretSize; i += 16) {
    final int nextIndex = i + 8;
    writeLE64(seededSecret, i, readLE64(kSecretView, i) + seed);
    writeLE64(seededSecret, nextIndex, readLE64(kSecretView, nextIndex) - seed);
  }

  return seededSecret;
}

//
// Buffers
//

/// Reads a 32-bit little-endian integer from the specified buffer at the
/// specified byte offset. (If unspecified, [byteOffset] is 0 which means the
/// value is read from the start of the buffer.)
@pragma('vm:prefer-inline')
int readLE32(ByteData bd, [int byteOffset = 0]) =>
    bd.getUint32(byteOffset, Endian.little);

/// Reads a 64-bit little-endian integer from the specified buffer at the
/// specified byte offset. (If unspecified, [byteOffset] is 0 which means the
/// value is read from the start of the buffer.)
@pragma('vm:prefer-inline')
int readLE64(ByteData bd, [int byteOffset = 0]) =>
    bd.getUint64(byteOffset, Endian.little);

/// Writes the given [value] as a 64-bit little-endian integer at the specified
/// byte offset.
@pragma('vm:prefer-inline')
void writeLE64(ByteData bd, int byteOffset, int value) =>
    bd.setUint64(byteOffset, value, Endian.little);

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
