import 'dart:typed_data';

const int kXXHPrime32_1 = 0x9E3779B1;
const int kXXHPrime32_2 = 0x85EBCA77;
const int kXXHPrime32_3 = 0xC2B2AE3D;

const int kXXHPrime64_1 = 0x9E3779B185EBCA87;
const int kXXHPrime64_2 = 0xC2B2AE3D27D4EB4F;
const int kXXHPrime64_3 = 0x165667B19E3779F9;
const int kXXHPrime64_4 = 0x85EBCA77C2B2AE63;
const int kXXHPrime64_5 = 0x27D4EB2F165667C5;

const kSecretDefaultSize = 192;
const kSecretSizeMin = 136;

final kSecret = Uint8List.fromList([
  0xb8, 0xfe, 0x6c, 0x39, 0x23, 0xa4, 0x4b, 0xbe, 0x7c, 0x01, 0x81, 0x2c, //
  0xf7, 0x21, 0xad, 0x1c, 0xde, 0xd4, 0x6d, 0xe9, 0x83, 0x90, 0x97, 0xdb, //
  0x72, 0x40, 0xa4, 0xa4, 0xb7, 0xb3, 0x67, 0x1f, 0xcb, 0x79, 0xe6, 0x4e, //
  0xcc, 0xc0, 0xe5, 0x78, 0x82, 0x5a, 0xd0, 0x7d, 0xcc, 0xff, 0x72, 0x21, //
  0xb8, 0x08, 0x46, 0x74, 0xf7, 0x43, 0x24, 0x8e, 0xe0, 0x35, 0x90, 0xe6, //
  0x81, 0x3a, 0x26, 0x4c, 0x3c, 0x28, 0x52, 0xbb, 0x91, 0xc3, 0x00, 0xcb, //
  0x88, 0xd0, 0x65, 0x8b, 0x1b, 0x53, 0x2e, 0xa3, 0x71, 0x64, 0x48, 0x97, //
  0xa2, 0x0d, 0xf9, 0x4e, 0x38, 0x19, 0xef, 0x46, 0xa9, 0xde, 0xac, 0xd8, //
  0xa8, 0xfa, 0x76, 0x3f, 0xe3, 0x9c, 0x34, 0x3f, 0xf9, 0xdc, 0xbb, 0xc7, //
  0xc7, 0x0b, 0x4f, 0x1d, 0x8a, 0x51, 0xe0, 0x4b, 0xcd, 0xb4, 0x59, 0x31, //
  0xc8, 0x9f, 0x7e, 0xc9, 0xd9, 0x78, 0x73, 0x64, 0xea, 0xc5, 0xac, 0x83, //
  0x34, 0xd3, 0xeb, 0xc3, 0xc5, 0x81, 0xa0, 0xff, 0xfa, 0x13, 0x63, 0xeb, //
  0x17, 0x0d, 0xdd, 0x51, 0xb7, 0xf0, 0xda, 0x49, 0xd3, 0x16, 0x55, 0x26, //
  0x29, 0xd4, 0x68, 0x9e, 0x2b, 0x16, 0xbe, 0x58, 0x7d, 0x47, 0xa1, 0xfc, //
  0x8f, 0xf8, 0xb8, 0xd1, 0x7a, 0xd0, 0x31, 0xce, 0x45, 0xcb, 0x3a, 0x8f, //
  0x95, 0x16, 0x04, 0x28, 0xaf, 0xd7, 0xfb, 0xca, 0xbb, 0x4b, 0x40, 0x7e, //
]);

class _PairInt {
  int lhs;
  int rhs;
  _PairInt(this.lhs, this.rhs);
}

_PairInt _mult64to128(int lhs, int rhs) {
  int loLo = (lhs.toUnsigned(32) * rhs.toUnsigned(32)).toUnsigned(64);
  int hiLo = (lhs >>> 32) * rhs.toUnsigned(32);
  int loHi = lhs.toUnsigned(32) * (rhs >>> 32);
  int hiHi = (lhs >>> 32) * (rhs >>> 32);
  int cross = (loLo >>> 32) + hiLo.toUnsigned(32) + loHi;
  int upper = (hiLo >>> 32) + (cross >>> 32) + hiHi;
  int lower = (cross << 32) | loLo.toUnsigned(32);
  return _PairInt(lower, upper);
}

int _mul128Fold64(int lhs, int rhs) {
  final product = _mult64to128(lhs, rhs);
  return product.lhs ^ product.rhs;
}

int _avalancheXXH64(int h) {
  h ^= h >>> 33;
  h *= kXXHPrime64_2;
  h ^= h >>> 29;
  h *= kXXHPrime64_3;
  return h ^ (h >>> 32);
}

int _avalancheXXH3(int h) {
  h ^= h >>> 37;
  h *= 0x165667919E3779F9;
  return h ^ (h >>> 32);
}

int _rotateLeft(int n, int count) {
  const bitCount = 64; // make it 32 for JavaScript compilation.
  assert(count >= 0 && count < bitCount);
  if (count == 0) return n;
  return (n << count) | ((n >= 0) ? n >> (bitCount - count) : ~(~n >> (bitCount - count)));
}

int _rrmxmx(int h, int length) {
  h ^= ((h << 49) | (h >>> 15)) ^ ((h << 24) | (h >>> 40));
  h *= 0x9FB21C651E98DF25;
  h ^= (h >>> 35) + length;
  h *= 0x9FB21C651E98DF25;
  return h ^ (h >>> 28);
}

int _mix16B(dynamic input, dynamic secret, int seed, {int inputOffset = 0, int secretOffset = 0}) {
  return _mul128Fold64(
    _readLE64(input, inputOffset) ^ (_readLE64(secret, secretOffset) + seed),
    _readLE64(input, inputOffset + 8) ^ (_readLE64(secret, secretOffset + 8) - seed),
  );
}

int _swap32(int x) {
  return ((x << 24) & 0xff000000) | ((x << 8) & 0x00ff0000) | ((x >>> 8) & 0x0000ff00) | ((x >>> 24) & 0x000000ff);
}

Uint8List _reverseBytes(Uint8List bytes) {
  int length = bytes.length;
  Uint8List result = Uint8List(length);
  for (int i = 0; i < length; i++) {
    result[i] = bytes[length - 1 - i];
  }
  return result;
}

int _swap64(int x) {
  return ((x << 56) & 0xff00000000000000) |
      ((x << 40) & 0x00ff000000000000) |
      ((x << 24) & 0x0000ff0000000000) |
      ((x << 8) & 0x000000ff00000000) |
      ((x >>> 8) & 0x00000000ff000000) |
      ((x >>> 24) & 0x0000000000ff0000) |
      ((x >>> 40) & 0x000000000000ff00) |
      ((x >>> 56) & 0x00000000000000ff);
}

const int kStripeLength = 64;
const int kSecretConsumeRate = 8;
const int kAccNB = 8;

int _readLE32(Uint8List value, [int byteOffset = 0]) {
  return ByteData.sublistView(value).getUint32(byteOffset, Endian.little);
}

int _readLE64(Uint8List value, [int byteOffset = 0]) {
  return ByteData.sublistView(value).getUint64(byteOffset, Endian.little);
}

typedef HashLongFunction = int Function(dynamic input, int length, int seed, dynamic secret, int secretLength);

void _accumulate512(List<int> acc, dynamic input, dynamic secret) {
  for (int i = 0; i < kAccNB; i++) {
    int dataVal = _readLE64(input, 8 * i);
    int dataKey = dataVal ^ _readLE64(secret, i * 8);
    acc[i ^ 1] += dataVal;
    acc[i] += dataKey.toUnsigned(32) * (dataKey >>> 32);
  }
}

int _hashLong64bInternal(dynamic input, int length, dynamic secret, int secretLength) {
  final acc = [kXXHPrime32_3, kXXHPrime64_1, kXXHPrime64_2, kXXHPrime64_3, kXXHPrime64_4, kXXHPrime32_2, kXXHPrime64_5, kXXHPrime32_1];
  int nbStripesPerBlock = (secretLength - kStripeLength) ~/ kSecretConsumeRate;
  int blockLen = kStripeLength * nbStripesPerBlock;
  int nbBlocks = (length - 1) ~/ blockLen;

  for (int n = 0; n < nbBlocks; n++) {
    for (int i = 0; i < nbStripesPerBlock; i++) {
      _accumulate512(
        acc,
        input + n * blockLen + i * kStripeLength,
        secret + i * kSecretConsumeRate,
      );
    }

    for (int i = 0; i < kAccNB; i++) {
      acc[i] = (acc[i] ^ (acc[i] >>> 47) ^ _readLE64(secret, secretLength - kStripeLength + 8 * i)) * kXXHPrime32_1;
    }
  }

  int nbStripes = ((length - 1) - (blockLen * nbBlocks)) ~/ kStripeLength;
  for (int i = 0; i < nbStripes; i++) {
    _accumulate512(acc, input + nbBlocks * blockLen + i * kStripeLength, secret + i * kSecretConsumeRate);
  }
  _accumulate512(acc, input + length - kStripeLength, secret + secretLength - kStripeLength - 7);
  int result = length * kXXHPrime64_1;
  for (int i = 0; i < 4; i++) {
    result += _mul128Fold64(acc[2 * i] ^ _readLE64(secret, 11 + 16 * i), acc[2 * i + 1] ^ _readLE64(secret, 11 + 16 * i + 8));
  }
  return _avalancheXXH3(result);
}

int _xXH3_64bitsInternal(Uint8List input, int length, int seed, Uint8List secret, int secretLength, HashLongFunction hashLongFunction) {
  if (length == 0) {
    return _avalancheXXH64(seed ^ (_readLE64(secret, 56) ^ _readLE64(secret, 64)));
  } else if (length < 4) {
    int keyed = ((((input[0]).toUnsigned(8)).toUnsigned(32) << 16) |
            (((input[length >>> 1]).toUnsigned(8)).toUnsigned(32) << 24) |
            input[length - 1].toUnsigned(8) |
            ((length).toUnsigned(32) << 8)) ^
        ((_readLE32(secret) ^ _readLE32(secret, 4)) + seed);

    return _avalancheXXH64(keyed);
  } else if (length <= 8) {
    int keyed = (_readLE32(input, length - 4) + ((_readLE32(input)) << 32)) ^
        ((_readLE64(secret, 8) ^ _readLE64(secret, 16)) - (seed ^ ((_swap32((seed).toUnsigned(32))) << 32)));
    return _rrmxmx(keyed, length);
  } else if (length <= 16) {
    int inputLo = _readLE64(input) ^ ((_readLE64(secret, 24) ^ _readLE64(secret, 32)) + seed);
    int inputHi = _readLE64(input, length - 8) ^ ((_readLE64(secret, 40) ^ _readLE64(secret, 48)) - seed);
    int acc = length + _swap64(inputLo) + inputHi + _mul128Fold64(inputLo, inputHi);
    return _avalancheXXH3(acc);
  } else if (length <= 128) {
    int acc = length * kXXHPrime64_1;
    int secretOff = 0;
    for (int i = 0, j = length; j > i; i += 16, j -= 16) {
      acc += _mix16B(input, secret, seed, inputOffset: i, secretOffset: secretOff);
      acc += _mix16B(input, secret, seed, inputOffset: j - 16, secretOffset: secretOff + 16);
      secretOff += 32;
    }
    return _avalancheXXH3(acc);
  } else if (length <= 240) {
    int acc = length * kXXHPrime64_1;
    int nbRounds = length ~/ 16;

    int i = 0;
    for (; i < 8; ++i) {
      acc += _mix16B(input, secret, seed, inputOffset: 16 * i, secretOffset: 16 * i);
    }
    acc = _avalancheXXH3(acc);

    for (; i < nbRounds; ++i) {
      acc += _mix16B(input, secret, seed, inputOffset: 16 * i, secretOffset: 16 * (i - 8) + 3);
    }

    acc += _mix16B(input, secret, seed, inputOffset: length - 16, secretOffset: kSecretSizeMin - 17);
    return _avalancheXXH3(acc);
  } else {
    return hashLongFunction(input, length, seed, secret, secretLength);
  }
}

xXH3_64bitsConst(List<int> input) {
  final inputBuffer = Uint8List.fromList(input);

  return _xXH3_64bitsInternal(
      inputBuffer,
      inputBuffer.lengthInBytes,
      0,
      kSecret,
      kSecret.lengthInBytes,
      (dynamic input, int length, int seed, dynamic secret, int secretLength) => _hashLong64bInternal(
            input,
            length,
            secret,
            secretLength,
          ));
}
