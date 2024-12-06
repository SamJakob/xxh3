import 'dart:typed_data';

import 'package:xxh3/src/constants.dart';
import 'package:xxh3/src/secret.dart';

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
void resetAccumulator(final Uint64List acc) {
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
void scrambleAccumulator(
  final Uint64List acc,
  final ByteData secret, {
  final int secretOffset = 0,
}) {
  for (int i = 0; i < kAccNB; i++) {
    final accI = acc[i];
    acc[i] = accI ^ (accI >>> 47);
    acc[i] ^= readLE64(
      secret,
      (8 * i) + secretOffset,
    );
    acc[i] *= kXXHPrime32_1;
  }
}

/// Dart equivalent of the xxh3_accumulate_512 function from XXH3.
@pragma('vm:prefer-inline')
void accumulate512(
  final Uint64List acc, {
  required final ByteData input,
  required final ByteData secret,
  final int inputOffset = 0,
  final int secretOffset = 0,
}) {
  int dataVal;
  int dataKey;

  for (int i = 0; i < kAccNB; i++) {
    final dataOffset = i * 8;
    dataVal = readLE64(input, inputOffset + dataOffset);
    dataKey = dataVal ^ readLE64(secret, secretOffset + dataOffset);

    acc[i ^ 1] += dataVal;
    acc[i] += (dataKey & 0xFFFFFFFF) * (dataKey >>> 32);
  }
}

/// Dart equivalent of the xxh3_accumulate function from XXH3. This function
/// performs [accumulate512] for each of the [stripes].
@pragma('vm:prefer-inline')
void accumulate(
  final Uint64List acc, {
  required final ByteData input,
  required final ByteData secret,
  required final int stripes,
  final int inputOffset = 0,
  final int secretOffset = 0,
}) {
  for (int i = 0; i < stripes; i++) {
    accumulate512(
      acc,
      input: input,
      secret: secret,
      inputOffset: (i * kStripeLength) + inputOffset,
      secretOffset: (i * kSecretConsumeRate) + secretOffset,
    );
  }
}

/// Dart equivalent of the xxh3_avalanche.
/// A fast avalanche stage for when input bits have been already partially
/// mixed.
@pragma('vm:prefer-inline')
int xxh3Avalanche(int h) {
  h ^= h >>> 37;
  h *= 0x165667919E3779F9;
  return h ^ (h >>> 32);
}

/// Validates that the secret is at least [kSecretSizeMin] bytes. If it isn't,
/// throws an [ArgumentError.value]. This function is reused to ensure the error
/// is consistent.
@pragma('vm:prefer-inline')
void validateSecret(final TypedData secret) {
  if (secret.lengthInBytes < kSecretSizeMin) {
    throw ArgumentError.value(
      secret,
      'secret',
      'The specified secret is too short. It must be at least $kSecretSizeMin bytes.',
    );
  }
}

/// Initializes the built-in secret with the user-provided [seed].
///
/// (If a custom seed is provided with the default secret, the default secret is
/// first seeded with this function).
@pragma('vm:prefer-inline')
ByteData initializeCustomSecret(final int seed) {
  final seededSecret = ByteData.view(Uint8List(kSecretSize).buffer);

  for (int i = 0; i < kSecretSize; i += 16) {
    final int nextIndex = i + 8;
    writeLE64(seededSecret, i, readLE64(kSecretView, i) + seed);
    writeLE64(seededSecret, nextIndex, readLE64(kSecretView, nextIndex) - seed);
  }

  return seededSecret;
}

/// CloneUint64List adds the [toUint64List] method to a [Uint64List], allowing
/// for cloning the list with a more conventional naming scheme.
extension CloneUint64List on Uint64List {
  /// Equivalent to calling [Uint64List.fromList] on the list. This is just an
  /// idiomatic alias that adheres to the `use_to_and_as_if_applicable` lint
  /// rule.
  ///
  /// Ultimately, this clones the list.
  Uint64List toUint64List() => Uint64List.fromList(this);
}

//
// Buffers
//

/// Reads a 32-bit little-endian integer from the specified buffer at the
/// specified byte offset. (If unspecified, [byteOffset] is 0 which means the
/// value is read from the start of the buffer.)
@pragma('vm:prefer-inline')
int readLE32(final ByteData bd, [final int byteOffset = 0]) =>
    bd.getUint32(byteOffset, Endian.little);

/// Reads a 64-bit little-endian integer from the specified buffer at the
/// specified byte offset. (If unspecified, [byteOffset] is 0 which means the
/// value is read from the start of the buffer.)
@pragma('vm:prefer-inline')
int readLE64(final ByteData bd, [final int byteOffset = 0]) =>
    bd.getUint64(byteOffset, Endian.little);

/// Writes the given [value] as a 64-bit little-endian integer at the specified
/// byte offset.
@pragma('vm:prefer-inline')
void writeLE64(final ByteData bd, final int byteOffset, final int value) =>
    bd.setUint64(byteOffset, value, Endian.little);

//
// Math
//

/// Multiplies [lhs] and [rhs], bitwise, then XORs the resulting pair of 64-bit
/// integers (the lower and upper half of the 128-bit output) to 'fold' it back
/// into a 64-bit integer.
@pragma('vm:prefer-inline')
int mul128Fold64(final int lhs, final int rhs) {
  final loLo = (lhs & 0xFFFFFFFF) * (rhs & 0xFFFFFFFF);
  final hiLo = (lhs >>> 32) * (rhs & 0xFFFFFFFF);
  final loHi = (lhs & 0xFFFFFFFF) * (rhs >>> 32);
  final hiHi = (lhs >>> 32) * (rhs >>> 32);
  final cross = (loLo >>> 32) + (hiLo & 0xFFFFFFFF) + loHi;
  final upper = (hiLo >>> 32) + (cross >>> 32) + hiHi;
  final lower = (cross << 32) | (loLo & 0xFFFFFFFF);
  return lower ^ upper;
}

/// Swaps the byte order of a 32-bit integer.
@pragma('vm:prefer-inline')
int swap32(final int x) =>
    ((x << 24) & 0xff000000) |
    ((x << 8) & 0x00ff0000) |
    ((x >>> 8) & 0x0000ff00) |
    ((x >>> 24) & 0x000000ff);

/// Swaps the byte order of a 64-bit integer.
@pragma('vm:prefer-inline')
int swap64(final int x) =>
    ((x << 56) & 0xff00000000000000) |
    ((x << 40) & 0x00ff000000000000) |
    ((x << 24) & 0x0000ff0000000000) |
    ((x << 8) & 0x000000ff00000000) |
    ((x >>> 8) & 0x00000000ff000000) |
    ((x >>> 24) & 0x0000000000ff0000) |
    ((x >>> 40) & 0x000000000000ff00) |
    ((x >>> 56) & 0x00000000000000ff);
