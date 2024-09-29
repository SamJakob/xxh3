library xxh3;

import 'dart:typed_data';

import 'package:xxh3/src/util.dart';
import 'package:xxh3/xxh3.dart';

part 'secret.dart';

const int kXXHPrime32_1 = 0x9E3779B1;
const int kXXHPrime32_2 = 0x85EBCA77;
const int kXXHPrime32_3 = 0xC2B2AE3D;

const int kXXHPrime64_1 = 0x9E3779B185EBCA87;
const int kXXHPrime64_2 = 0xC2B2AE3D27D4EB4F;
const int kXXHPrime64_3 = 0x165667B19E3779F9;
const int kXXHPrime64_4 = 0x85EBCA77C2B2AE63;
const int kXXHPrime64_5 = 0x27D4EB2F165667C5;

/// The number of secret bytes consumed at each accumulation.
const int kSecretConsumeRate = 8;
const int kStripeLength = 64;
const int kAccNB = 8; // = kStripeLength ~/ sizeof(uint64_t)

const int kXXH3MidSizeMax = 240;

/// A dart implementation of xxh64_avalanche.
/// Mixes all the bits to finalize the hash.
/// The final mix ensures the input bits have all had a chance to impact any
/// bit in the output digest thereby removing bias from the distribution.
int _xXH64Avalanche(int h) {
  h ^= h >>> 33;
  h *= kXXHPrime64_2;
  h ^= h >>> 29;
  h *= kXXHPrime64_3;
  return h ^ (h >>> 32);
}

/// Dart implementation of the xxh3_avalanche.
/// A fast avalanche stage for when input bits have been already partially
/// mixed.
@pragma('vm:prefer-inline')
int _xXH3Avalanche(int h) {
  h ^= h >>> 37;
  h *= 0x165667919E3779F9;
  return h ^ (h >>> 32);
}

/// Dart implementation of the xxh3_rrmxmx.
/// Based on Pelle Evensen's rrmxmx and preferred when input has not been
/// mixed.
int _xXH3rrmxmx(int h, int length) {
  h ^= ((h << 49) | (h >>> 15)) ^ ((h << 24) | (h >>> 40));
  h *= 0x9FB21C651E98DF25;
  h ^= (h >>> 35) + length;
  h *= 0x9FB21C651E98DF25;
  return h ^ (h >>> 28);
}

/// Dart implementation of the xxh3_mix16b hash function from XXH3.
int _xXH3Mix16B(ByteData input, ByteData secret, int seed,
    {int inputOffset = 0, int secretOffset = 0}) {
  return mul128Fold64(
    readLE64(input, inputOffset) ^ (readLE64(secret, secretOffset) + seed),
    readLE64(input, inputOffset + 8) ^
        (readLE64(secret, secretOffset + 8) - seed),
  );
}

/// Dart implementation of the xxh3_accumulate_512 hash function from XXH3.
void _xXH3Accumulate512(Uint64List acc, ByteData input, ByteData secret,
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

/// The default [HashLongFunction] for XXH3.
int xXH3HashLong64bInternal(ByteData input, int seed, ByteData secret) {
  final int length = input.lengthInBytes;

  final int secretLength;

  if (seed == 0) {
    secret = kSecretView;
    secretLength = kSecretSize;
  } else {
    if (secret == kSecretView) {
      final seededSecret = ByteData.view(Uint8List(kSecretSize).buffer);

      for (int i = 0; i < kSecretSize; i += 16) {
        final int nextIndex = i + 8;
        seededSecret.setUint64(
            i, readLE64(kSecretView, i) + seed, Endian.little);
        seededSecret.setUint64(
            nextIndex, readLE64(kSecretView, nextIndex) - seed, Endian.little);
      }

      secret = seededSecret;
    }

    secret = ByteData.view(secret.buffer);
    secretLength = secret.lengthInBytes;
  }

  final acc = Uint64List(8);
  acc[0] = kXXHPrime32_3;
  acc[1] = kXXHPrime64_1;
  acc[2] = kXXHPrime64_2;
  acc[3] = kXXHPrime64_3;
  acc[4] = kXXHPrime64_4;
  acc[5] = kXXHPrime32_2;
  acc[6] = kXXHPrime64_5;
  acc[7] = kXXHPrime32_1;

  int nbStripesPerBlock = (secretLength - kStripeLength) ~/ kSecretConsumeRate;
  int blockLen = kStripeLength * nbStripesPerBlock;
  int nbBlocks = (length - 1) ~/ blockLen;

  for (int n = 0; n < nbBlocks; n++) {
    for (int i = 0; i < nbStripesPerBlock; i++) {
      _xXH3Accumulate512(
        acc,
        input,
        secret,
        inputOffset: n * blockLen + i * kStripeLength,
        secretOffset: i * kSecretConsumeRate,
      );
    }

    for (int i = 0; i < kAccNB; i++) {
      final accI = acc[i];
      acc[i] = (accI ^
              (accI >>> 47) ^
              readLE64(secret, secretLength - kStripeLength + 8 * i)) *
          kXXHPrime32_1;
    }
  }

  int nbStripes = ((length - 1) - (blockLen * nbBlocks)) ~/ kStripeLength;
  for (int i = 0; i < nbStripes; i++) {
    _xXH3Accumulate512(
      acc,
      input,
      secret,
      inputOffset: nbBlocks * blockLen + i * kStripeLength,
      secretOffset: i * kSecretConsumeRate,
    );
  }
  _xXH3Accumulate512(
    acc,
    input,
    secret,
    inputOffset: length - kStripeLength,
    secretOffset: secretLength - kStripeLength - 7,
  );
  int result = length * kXXHPrime64_1;
  for (int i = 0; i < 4; i++) {
    final int accOffset = 2 * i;
    final int secretOffset = 11 + 16 * i;

    result += mul128Fold64(
      acc[accOffset] ^ readLE64(secret, secretOffset),
      acc[accOffset + 1] ^ readLE64(secret, secretOffset + 8),
    );
  }
  return _xXH3Avalanche(result);
}

/// The internal entry point for the 64-bit variant of the XXH3 hash.
int xXH3_64bitsInternal({
  required Uint8List input,
  required int seed,
  required Uint8List secret,
  required HashLongFunction hashLongFunction,
}) {
  if (secret.lengthInBytes < kSecretSizeMin) {
    throw ArgumentError.value(
      secret,
      'secret',
      "The specified secret is too short. It must be at least $kSecretSizeMin bytes.",
    );
  }

  final inputView = ByteData.view(input.buffer);
  int length = input.lengthInBytes;

  // Refer to XXH3_64bits_withSecretAndSeed, notice that if the seed is not
  // the default and the length is less than the midSizeMax, a custom secret
  // will be ignored.
  if (seed != 0 && length <= kXXH3MidSizeMax && secret != kSecret) {
    secret = kSecret;
    // The original source code also specifies hashLong as NULL, I'm assuming
    // that's because it would never be used with the length being less than
    // kXXH3MidSizeMax, rather than as a preventative measure.
  }

  final secretView =
      secret == kSecret ? kSecretView : ByteData.view(secret.buffer);

  if (length > 240) {
    return hashLongFunction(inputView, seed, secretView);
  }

  if (length == 0) {
    return _xXH64Avalanche(
        seed ^ (readLE64(secretView, 56) ^ readLE64(secretView, 64)));
  } else if (length < 4) {
    int keyed = ((((input[0])) << 16) |
            (((input[length >>> 1])) << 24) |
            input[length - 1] |
            ((length) << 8)) ^
        ((readLE32(secretView) ^ readLE32(secretView, 4)) + seed);

    return _xXH64Avalanche(keyed);
  } else if (length <= 8) {
    int keyed =
        (readLE32(inputView, length - 4) + ((readLE32(inputView)) << 32)) ^
            ((readLE64(secretView, 8) ^ readLE64(secretView, 16)) -
                (seed ^ ((swap32((seed))) << 32)));
    return _xXH3rrmxmx(keyed, length);
  } else if (length <= 16) {
    int inputLo = readLE64(inputView) ^
        ((readLE64(secretView, 24) ^ readLE64(secretView, 32)) + seed);
    int inputHi = readLE64(inputView, length - 8) ^
        ((readLE64(secretView, 40) ^ readLE64(secretView, 48)) - seed);
    int acc =
        length + swap64(inputLo) + inputHi + mul128Fold64(inputLo, inputHi);
    return _xXH3Avalanche(acc);
  } else if (length <= 128) {
    int acc = length * kXXHPrime64_1;
    int secretOff = 0;
    for (int i = 0, j = length; j > i; i += 16, j -= 16) {
      acc += _xXH3Mix16B(inputView, secretView, seed,
          inputOffset: i, secretOffset: secretOff);
      acc += _xXH3Mix16B(inputView, secretView, seed,
          inputOffset: j - 16, secretOffset: secretOff + 16);
      secretOff += 32;
    }
    return _xXH3Avalanche(acc);
  } else {
    // length <= 240
    int acc = length * kXXHPrime64_1;
    int nbRounds = length ~/ 16;

    int i = 0;
    for (; i < 8; ++i) {
      acc += _xXH3Mix16B(inputView, secretView, seed,
          inputOffset: 16 * i, secretOffset: 16 * i);
    }
    acc = _xXH3Avalanche(acc);

    for (; i < nbRounds; ++i) {
      acc += _xXH3Mix16B(inputView, secretView, seed,
          inputOffset: 16 * i, secretOffset: 16 * (i - 8) + 3);
    }

    acc += _xXH3Mix16B(inputView, secretView, seed,
        inputOffset: length - 16, secretOffset: kSecretSizeMin - 17);
    return _xXH3Avalanche(acc);
  }
}
