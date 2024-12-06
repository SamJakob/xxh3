import 'dart:convert' show utf8;
import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:xxh3/xxh3.dart' hide xxh3, xxh3String;

import 'common_known_answers.dart';
import 'utils.dart';

/// The result of hashing "Hello, world!" (stream API).
const kXXH3StreamHelloWorld = 0xf3c34bf11915e869;

/// The result of duplicating the call to update with "Hello, world!" (stream
/// API).
const kXXH3StreamHelloWorldTwice = 0xb66b4a6341f6226a;
const kXXH3StreamHelloWorldTwiceString = 'b66b4a6341f6226a';
const kXXH3StreamHelloWorld512Times = 0xd98b206f50336968;

/// The result of duplicating a call to update with "a' many times (stream API).
///
/// The known answer has been produced with the reference xxHash library as
/// follows:
///
/// ```c
/// // Example C code.
///
/// #include <stdio.h>
/// #include <assert.h>
///
/// #define XXH_STATIC_LINKING_ONLY
/// #define XXH_IMPLEMENTATION
///
/// // Adjust accordingly.
/// #define CHAR_REPEAT_COUNT 240
///
/// #include "xxhash.h"
///
/// int main(void) {
///         XXH3_state_t* state = XXH3_createState();
///         assert(state != NULL && "Out of memory!");
///
///         XXH3_64bits_reset(state);
///         const char* buffer = "a";
///
///         for (int i = 0; i < CHAR_REPEAT_COUNT; i++)
///                 XXH3_64bits_update(state, buffer, strlen(buffer));
///
///         XXH64_hash_t result = XXH3_64bits_digest(state);
///         printf("%llx\n", result);
///
///         XXH3_freeState(state);
///         return 0;
/// }
/// ```
const kXXH3StreamSingleChar240Times = 0x993c46d96a01b5c6;
const kXXH3StreamSingleChar241Times = 0xf6cfef5c5aca1930;
const kXXH3StreamSingleChar256Times = 0x3fdb4ff1846c90f3;
const kXXH3StreamSingleChar257Times = 0x4dd04767c00e03f1;
const kXXH3StreamSingleChar512Times = 0x4659a548a9cc8db1;

/// The result of calling update 512 times with a string containing the letter
/// 'a' 1024 times.
///
/// The known answer has been produced with the reference xxHash library as
/// follows:
///
/// ```c
///#include <stdio.h>
/// #include <assert.h>
///
/// #define XXH_STATIC_LINKING_ONLY
/// #define XXH_IMPLEMENTATION
/// #define XXH_VECTOR XXH_SCALAR
///
/// #include "xxhash.h"
///
/// int main(void) {
/// 	XXH3_state_t* state = XXH3_createState();
/// 	assert(state != NULL && "Out of memory!");
///
/// 	XXH3_64bits_reset(state);
/// 	const char buffer[1024] = {0};
/// 	memset(buffer, 'a', sizeof(buffer));
///
/// 	for (int i = 0; i < 512; i++)
/// 		XXH3_64bits_update(state, buffer, sizeof(buffer));
///
/// 	const XXH64_hash_t result = XXH3_64bits_digest(state);
/// 	printf("hex: %llx\n", result);
/// 	printf("dec: %lld\n", result);
///
/// 	XXH3_freeState(state);
/// 	return 0;
/// }
/// ```
const kXXH3Stream1024CharString512Times = 0xc47016661db2c2aa;

/// The result of hashing the `example/example_pubspec.yml` file.
///
/// The known answer has been produced with the reference xxHash library as
/// follows:
///
/// ```c
///#define XXH_NO_STDLIB
/// #define XXH_STATIC_LINKING_ONLY
/// #define XXH_IMPLEMENTATION
/// #define XXH_VECTOR XXH_SCALAR
///
/// #include "xxhash.h"
///
/// #include <stdio.h>
/// #include <fcntl.h>
/// #include <unistd.h>
/// #include <sys/errno.h>
/// #include <stdlib.h>
///
/// #define BUFFER_SIZE (1024)
///
/// void terminate(const char* message) {
///   printf("%s\n", message);
///   exit(1);
/// }
///
/// int main(const int argc, const char** argv) {
///   if (argc < 2) {
///     const char* binary_name = "xxh3_hash";
///     printf("Usage: %s <file>\n", argc < 1 ? binary_name : argv[0]);
///     exit(1);
///   }
///
///   const char* file = argv[1];
///
///   XXH3_state_t state = {0};
///   if (XXH3_64bits_reset(&state) != XXH_OK) terminate("Failed to initialize XXH3");
///
///   const int fd = open(file, O_RDONLY);
///   if (fd == -1) terminate("Failed to open file.");
///
///   char buffer[BUFFER_SIZE] = {0};
///   ssize_t bytes_read = 0;
///   while ((bytes_read = read(fd, buffer, BUFFER_SIZE)) > 0) {
///     if (XXH3_64bits_update(&state, buffer, bytes_read) != XXH_OK) {
///       printf("XXH3 error.\n");
///     }
///   }
///
///   if (bytes_read < 0) {
///     printf("ERRNO: %d", errno);
///     terminate("Encountered an error whilst reading the file.");
///   }
///
///   if (close(fd) == -1) {
///     printf("ERRNO: %d", errno);
///     terminate("Encountered an error whilst closing the file.");
///   }
///
///   const XXH64_hash_t result = XXH3_64bits_digest(&state);
///   printf("hex: %llx\n", result);
///   printf("dec: %lld\n", result);
///   return 0;
/// }
/// ```
const kXXH3StreamExamplePubspecFile = 0x338a9d0094ba6f8;

void main() {
  group('Test stream API against known values', () {
    late XXH3State hashStream;

    setUp(() {
      hashStream = xxh3Stream();
    });

    test('Hashing "Hello, world!"', () {
      hashStream.update(utf8.encode('Hello, world!'));
      expect(hashStream.digest(), equals(kXXH3StreamHelloWorld));
    });

    test('Hashing "Hello, world!" twice', () {
      hashStream
        ..update(utf8.encode('Hello, world!'))
        ..update(utf8.encode('Hello, world!'));
      expect(hashStream.digest(), equals(kXXH3StreamHelloWorldTwice));
    });

    test('Hashing "a" 240 times', () {
      for (int i = 0; i < 240; i++) {
        hashStream.update(utf8.encode('a'));
      }

      expect(hashStream.digest(), equals(kXXH3StreamSingleChar240Times));
    });

    test('Hashing "a" 241 times', () {
      for (int i = 0; i < 241; i++) {
        hashStream.update(utf8.encode('a'));
      }

      expect(hashStream.digest(), equals(kXXH3StreamSingleChar241Times));
    });

    test('Hashing "a" 256 times', () {
      for (int i = 0; i < 256; i++) {
        hashStream.update(utf8.encode('a'));
      }

      expect(hashStream.digest(), equals(kXXH3StreamSingleChar256Times));
    });

    test('Hashing "a" 257 times', () {
      for (int i = 0; i < 257; i++) {
        hashStream.update(utf8.encode('a'));
      }

      expect(hashStream.digest(), equals(kXXH3StreamSingleChar257Times));
    });
  });

  group('Test buffered hashing', () {
    late XXH3State hashStream;

    setUp(() {
      hashStream = xxh3Stream();
    });

    test('Hashing "a" 512 times', () {
      for (int i = 0; i < 512; i++) {
        hashStream.update(utf8.encode('a'));
      }

      expect(hashStream.digest(), equals(kXXH3StreamSingleChar512Times));
    });

    test('Hashing "Hello, world!" 512 times', () {
      for (int i = 0; i < 512; i++) {
        hashStream.update(utf8.encode('Hello, world!'));
      }

      expect(hashStream.digest(), equals(kXXH3StreamHelloWorld512Times));
    });

    test('Hashing 1024 "a"s, 512 times', () {
      for (int i = 0; i < 512; i++) {
        hashStream.update(utf8.encode('a' * 1024));
      }

      expect(hashStream.digest(), equals(kXXH3Stream1024CharString512Times));
    });
  });

  group('Test hashing example/example_pubspec.yml against known value', () {
    late final File file;
    setUpAll(() {
      file = File('example/example_pubspec.yml');
    });

    test('openRead() as-is', () async {
      final hashStream = xxh3Stream();
      await file.openRead().map(Uint8List.fromList).forEach(hashStream.update);
      expect(hashStream.digest(), equals(kXXH3StreamExamplePubspecFile));
    });

    test(
      'openRead() chunked into kXXH3StreamBufferSize (256) chunks',
      () async {
        final hashStream = xxh3Stream();
        await file
            .openRead()
            .chunked(kXXH3StreamBufferSize)
            .map(Uint8List.fromList)
            .forEach(hashStream.update);
        expect(hashStream.digest(), equals(kXXH3StreamExamplePubspecFile));
      },
    );

    test('openRead() byte-by-byte', () async {
      final hashStream = xxh3Stream();
      await file
          .openRead()
          .chunked(1)
          .map(Uint8List.fromList)
          .forEach(hashStream.update);
      expect(hashStream.digest(), equals(kXXH3StreamExamplePubspecFile));
    });
  });

  group('digest and digestString should be idempotent', () {
    late XXH3State hashStream;

    setUp(() {
      hashStream = xxh3Stream();
    });

    test('digest', () {
      hashStream
        ..update(utf8.encode('Hello, world!'))
        ..update(utf8.encode('Hello, world!'));
      expect(hashStream.digest(), equals(kXXH3StreamHelloWorldTwice));
      expect(hashStream.digest(), equals(kXXH3StreamHelloWorldTwice));
    });

    test('digestString', () {
      hashStream
        ..update(utf8.encode('Hello, world!'))
        ..update(utf8.encode('Hello, world!'));
      expect(
        hashStream.digestString(),
        equals(kXXH3StreamHelloWorldTwiceString),
      );
      expect(
        hashStream.digestString(),
        equals(kXXH3StreamHelloWorldTwiceString),
      );
    });
  });

  group('Test against known hash values', () {
    testKnownAnswers((
      final Uint8List input, {
      final Uint8List? secret,
      final int? seed,
    }) {
      final hashStream = xxh3Stream(secret: secret, seed: seed)..update(input);
      return hashStream.digest();
    });
  });

  group('Error handling', () {
    test('Invalid custom secret length', () {
      void testInvalidSecretLength(final int length) {
        expect(
          () => XXH3State.create(secret: Uint8List(length)),
          throwsA(
            isA<ArgumentError>().having(
              (final e) => e.message,
              'message',
              contains('secret is too short'),
            ),
          ),
        );
      }

      testInvalidSecretLength(0);
      testInvalidSecretLength(kSecretSizeMin - 1);
    });
  });
}
