import 'dart:typed_data';

import 'package:xxh3/src/constants.dart';
import 'package:xxh3/src/secret.dart';
import 'package:xxh3/src/util.dart';
import 'package:xxh3/xxh3.dart';

/// A dart implementation of xxh64_avalanche.
/// Mixes all the bits to finalize the hash.
/// The final mix ensures the input bits have all had a chance to impact any
/// bit in the output digest thereby removing bias from the distribution.
int _xxh64Avalanche(int h) {
  h ^= h >>> 33;
  h *= kXXHPrime64_2;
  h ^= h >>> 29;
  h *= kXXHPrime64_3;
  return h ^ (h >>> 32);
}

/// Dart implementation of the xxh3_rrmxmx.
/// Based on Pelle Evensen's rrmxmx and preferred when input has not been
/// mixed.
int _xxh3rrmxmx(int h, final int length) {
  h ^= ((h << 49) | (h >>> 15)) ^ ((h << 24) | (h >>> 40));
  h *= 0x9FB21C651E98DF25;
  h ^= (h >>> 35) + length;
  h *= 0x9FB21C651E98DF25;
  return h ^ (h >>> 28);
}

/// Dart implementation of the xxh3_mix16b hash function from XXH3.
int _xxh3Mix16B({
  required final ByteData input,
  required final ByteData secret,
  required final int seed,
  final int inputOffset = 0,
  final int secretOffset = 0,
}) =>
    mul128Fold64(
      readLE64(input, inputOffset) ^ (readLE64(secret, secretOffset) + seed),
      readLE64(input, inputOffset + 8) ^
          (readLE64(secret, secretOffset + 8) - seed),
    );

/// The default [HashLongFunction] for XXH3.
int xxh3_64HashLongInternal(
  final ByteData input,
  final int seed,
  ByteData secret,
) {
  final int length = input.lengthInBytes;

  final int secretLength;

  if (seed == 0) {
    secret = kSecretView;
    secretLength = kSecretSize;
  } else {
    if (secret == kSecretView) {
      secret = initializeCustomSecret(seed);
      secretLength = kSecretSize;
    } else {
      secret = ByteData.view(secret.buffer);
      secretLength = secret.lengthInBytes;
    }
  }

  final acc = createAccumulator();
  final nbStripesPerBlock =
      (secretLength - kStripeLength) ~/ kSecretConsumeRate;
  final blockLen = kStripeLength * nbStripesPerBlock;
  final nbBlocks = (length - 1) ~/ blockLen;

  for (int n = 0; n < nbBlocks; n++) {
    accumulate(
      acc,
      input: input,
      secret: secret,
      inputOffset: n * blockLen,
      stripes: nbStripesPerBlock,
    );
    scrambleAccumulator(
      acc,
      secret,
      secretOffset: secret.lengthInBytes - kStripeLength,
    );
  }

  final nbStripes = ((length - 1) - (blockLen * nbBlocks)) ~/ kStripeLength;
  accumulate(
    acc,
    input: input,
    secret: secret,
    inputOffset: nbBlocks * blockLen,
    stripes: nbStripes,
  );

  accumulate512(
    acc,
    input: input,
    secret: secret,
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
  return xxh3Avalanche(result);
}

/// The internal entry point for the 64-bit variant of the XXH3 hash.
int xxh3_64Internal({
  required final Uint8List input,
  required final int seed,
  required final HashLongFunction hashLongFunction,
  Uint8List? secret,
}) {
  if (secret != null) {
    validateSecret(secret);
  }

  final inputView = ByteData.view(input.buffer);
  final length = input.lengthInBytes;

  // Refer to XXH3_64bits_withSecretAndSeed, notice that if the seed is not
  // the default and the length is less than the 'small data size', a custom
  // secret will be ignored.
  if (seed != 0 && length <= kXXH3SmallDataSize && secret != null) {
    secret = null;
    // The original source code also specifies hashLong as NULL, I'm assuming
    // that's because it would never be used with the length being less than
    // kXXH3MidSizeMax, rather than as a preventative measure.
  }

  final secretView =
      secret != null ? ByteData.view(secret.buffer) : kSecretView;

  // If the length indicates that the key (i.e., data being hashed) is not
  // 'short', then use the hashLongFunction.
  if (length > kXXH3SmallDataSize) {
    return hashLongFunction(inputView, seed, secretView);
  }

  if (length == 0) {
    return _xxh64Avalanche(
      seed ^ (readLE64(secretView, 56) ^ readLE64(secretView, 64)),
    );
  } else if (length < 4) {
    final keyed = (((input[0]) << 16) |
            ((input[length >>> 1]) << 24) |
            input[length - 1] |
            (length << 8)) ^
        ((readLE32(secretView) ^ readLE32(secretView, 4)) + seed);

    return _xxh64Avalanche(keyed);
  } else if (length <= 8) {
    final keyed =
        (readLE32(inputView, length - 4) + ((readLE32(inputView)) << 32)) ^
            ((readLE64(secretView, 8) ^ readLE64(secretView, 16)) -
                (seed ^ ((swap32(seed)) << 32)));
    return _xxh3rrmxmx(keyed, length);
  } else if (length <= 16) {
    final inputLo = readLE64(inputView) ^
        ((readLE64(secretView, 24) ^ readLE64(secretView, 32)) + seed);
    final inputHi = readLE64(inputView, length - 8) ^
        ((readLE64(secretView, 40) ^ readLE64(secretView, 48)) - seed);
    final acc =
        length + swap64(inputLo) + inputHi + mul128Fold64(inputLo, inputHi);
    return xxh3Avalanche(acc);
  } else if (length <= 128) {
    int acc = length * kXXHPrime64_1;
    int secretOffset = 0;

    for (int i = 0, j = length; j > i; i += 16, j -= 16) {
      acc += _xxh3Mix16B(
        input: inputView,
        secret: secretView,
        seed: seed,
        inputOffset: i,
        secretOffset: secretOffset,
      );
      acc += _xxh3Mix16B(
        input: inputView,
        secret: secretView,
        seed: seed,
        inputOffset: j - 16,
        secretOffset: secretOffset + 16,
      );
      secretOffset += 32;
    }
    return xxh3Avalanche(acc);
  } else {
    // length <= 240
    final nbRounds = length ~/ 16;
    int acc = length * kXXHPrime64_1;

    int i = 0;
    for (; i < 8; ++i) {
      acc += _xxh3Mix16B(
        input: inputView,
        secret: secretView,
        seed: seed,
        inputOffset: 16 * i,
        secretOffset: 16 * i,
      );
    }
    acc = xxh3Avalanche(acc);

    for (; i < nbRounds; ++i) {
      acc += _xxh3Mix16B(
        input: inputView,
        secret: secretView,
        seed: seed,
        inputOffset: 16 * i,
        secretOffset: 16 * (i - 8) + 3,
      );
    }

    acc += _xxh3Mix16B(
      input: inputView,
      secret: secretView,
      seed: seed,
      inputOffset: length - 16,
      secretOffset: kSecretSizeMin - 17,
    );
    return xxh3Avalanche(acc);
  }
}
