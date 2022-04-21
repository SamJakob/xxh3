import 'dart:convert' show utf8;
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:xxh3/xxh3.dart';

// Hash results generated with XXH3 from:
// https://github.com/Cyan4973/xxHash

/// The result of hashing 0 bytes.
const kXXH3EmptyHash = 0x2d06800538d394c2;

/// The result of hashing 1 null byte.
const kXXH3NullHash = 0xc44bdff4074eecdb;

/// The result of hashing the string "ye".
const kXXH3yeHash = 0xd3a409d78a5fe0d3;

/// The result of hashing the string "hello".
const kXXH3helloHash = 0x9555e8555c62dcfd;

/// Not the result of hashing the string "hello".
const kXXH3helloHashInvalid = 0x9555e8555c62dcfe;

/// The result of hashing the string "howdy yall".
const kXXH3howdyyallHash = 0x8ea5ee5c96914d03;

/// Hash of the following 31-byte string:
/// "Howdy, partners! tree mushrooms"
const kXXH3_31ByteHash = 0x8e9f8eda2faf298d;

/// Hash of integers from 0 to 130.
const kXXH3_130ByteHash = 0x4d3224b100908a87;

/// Hash of integers from 0 to 163.
const kXXH3_163ByteHash = 0xaf23aa983bb0b162;

/// Hash of integers from 0 to 250.
const kXXH3_250ByteHash = 0x3a07e271a5dab0a3;

/// Hash of integers from 0 to 255, repeated until 2048 elements is reached.
const kXXH3_2048ByteHash = 0xdd420471ff96bd00;

/// Hash of "Hello, world!" with a custom secret (all null bytes of min secret
/// length).
const kXXH3CustomSecret = 0x7d433b528dca8e34;

/// Hash of "Hello, world!" with a custom seed and default secret.
const kXXH3CustomSeed = 0x8ec7b6d9d1d4b191;

/// Hash of "Hello, world!" with a custom seed and a custom secret (all null
/// bytes of min secret length).
const kXXH3CustomSecretAndSeed = 0x8ec7b6d9d1d4b191;

/// Like [kXXH3CustomSeed] but with a big payload (2048 bytes).
const kXXH3CustomSeedBigPayload = 0x941f28b00d8c4626;

/// Like [kXXH3CustomSecretAndSeed] but with a big payload (2048 bytes).
const kXXH3CustomSecretAndSeedBigPayload = 0xef152aac651d7cb1;

// Start tests.

/// UTF-8 encodes the specified string and returns the bytes in a [Uint8List].
Uint8List stringBytes(String value) {
  return Uint8List.fromList(utf8.encode(value));
}

/// Generates a [Uint8List] based on 8-bit integers from 0 to [max].
/// If [max] exceeds 255 (the 8-bit limit), the values will wrap around.
Uint8List rangeBytes(int max) {
  final rangeBytes = Uint8List(max);
  for (int i = 0; i < max; i++) {
    rangeBytes[i] = i % 256;
  }
  return rangeBytes;
}

void main() {
  group('Test against known hash values', () {
    test('Hashing 0 bytes', () {
      expect(xxh3(Uint8List(0)), equals(kXXH3EmptyHash));
    });

    test('Hashing 1 null byte = "\\0"', () {
      // Check a string with a null byte.
      expect(xxh3(stringBytes("\x00")), equals(kXXH3NullHash));
      // Also check a Uint8List with a null byte.
      // (Bytes are initialized to 0).
      expect(xxh3(Uint8List(1)), equals(kXXH3NullHash));
    });

    test('Hashing 3 bytes = "ye"', () {
      expect(xxh3(stringBytes("ye")), equals(kXXH3yeHash));
    });

    test('Hashing 5 bytes = "hello"', () {
      expect(xxh3(stringBytes("hello")), equals(kXXH3helloHash));
    });

    test('(Should fail) Hashing 5 bytes = "hello" and checking invalid value',
        () {
      expect(xxh3(stringBytes("hello")), isNot(kXXH3helloHashInvalid));
    });

    test('Hashing 10 bytes = "howdy yall"', () {
      expect(xxh3(stringBytes("howdy yall")), equals(kXXH3howdyyallHash));
    });

    test('Hashing 31 bytes = "Howdy, partners! tree mushrooms"', () {
      expect(xxh3(stringBytes("Howdy, partners! tree mushrooms")),
          equals(kXXH3_31ByteHash));
    });

    test('Hashing 130 bytes = (bytes = 0...130)', () {
      expect(xxh3(rangeBytes(130)), equals(kXXH3_130ByteHash));
    });

    test('Hashing 163 bytes = (bytes = 0...130)', () {
      expect(xxh3(rangeBytes(163)), equals(kXXH3_163ByteHash));
    });

    test('Hashing 250 bytes = (bytes = 0...250)', () {
      expect(xxh3(rangeBytes(250)), equals(kXXH3_250ByteHash));
    });

    test('Hashing 2048 bytes = (bytes = 0...255 - repeated)', () {
      expect(xxh3(rangeBytes(2048)), equals(kXXH3_2048ByteHash));
    });

    test('Using an invalid secret (too short) throws an error', () {
      expect(() => xxh3(stringBytes("Hello, world!"), secret: Uint8List(3)),
          throwsArgumentError);
    });

    test(
        'Using an valid secret does not throw an error (and yields correct hash)',
        () {
      // This secret is all zeroes. NEVER do this. See xxh3 documentation for
      // details.
      final secret = Uint8List(kSecretSizeMin);
      expect(xxh3(stringBytes("Hello, world!"), secret: secret),
          equals(kXXH3CustomSecret));
    });

    test('Using a custom seed yields correct hash', () {
      expect(xxh3(stringBytes("Hello, world!"), seed: 0x702),
          equals(kXXH3CustomSeed));
    });

    test('Using a custom seed with custom secret yields correct hash', () {
      // This secret is all zeroes. NEVER do this. See xxh3 documentation for
      // details.
      final secret = Uint8List(kSecretSizeMin);
      expect(xxh3(stringBytes("Hello, world!"), secret: secret, seed: 0x702),
          equals(kXXH3CustomSecretAndSeed));
    });

    test('Using a custom seed (with a big payload) yields correct hash', () {
      expect(xxh3(rangeBytes(2048), seed: 0x702),
          equals(kXXH3CustomSeedBigPayload));
    });

    test(
        'Using a custom seed with custom secret (with a big payload) yields correct hash',
        () {
      // This secret is all zeroes. NEVER do this. See xxh3 documentation for
      // details.
      final secret = Uint8List(kSecretSizeMin);
      expect(xxh3(rangeBytes(2048), secret: secret, seed: 0x702),
          equals(kXXH3CustomSecretAndSeedBigPayload));
    });
  });
}
