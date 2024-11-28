import 'dart:convert' show utf8;

import 'package:test/test.dart';
import 'package:xxh3/xxh3.dart';

/// The result of hashing "Hello, world!" (streaming API).
const kXXH3StreamHelloWorld = 0xf3c34bf11915e869;

/// The result of duplicating the call to update with "Hello, world!" (streaming
/// API).
const kXXH3StreamHelloWorldTwice = 0xb66b4a6341f6226a;
const kXXH3StreamHelloWorldTwiceString = "b66b4a6341f6226a";

const kXXH3StreamSingleChar240Times = 0x993c46d96a01b5c6;
const kXXH3StreamSingleChar241Times = 0xf6cfef5c5aca1930;

/// The result of calling update with 'a' 256 times.
const kXXH3StreamSingleChar256Times = 0x3fdb4ff1846c90f3;

/// The result of duplicating the call to update with "Hello, world!", 512 times
/// (streaming API).
const kXXH3StreamHelloWorld512Times = 0xd98b206f50336968;

/*
// Example C code.

#include <stdio.h>
#include <assert.h>

#define XXH_STATIC_LINKING_ONLY
#define XXH_IMPLEMENTATION

#include "xxhash.h"

int main(void) {
        XXH3_state_t* state = XXH3_createState();
        assert(state != NULL && "Out of memory!");

        XXH3_64bits_reset(state);
        const char* buffer = "a";

        for (int i = 0; i < 256; i++)
                XXH3_64bits_update(state, buffer, strlen(buffer));

        XXH64_hash_t result = XXH3_64bits_digest(state);
        printf("%llx\n", result);

        XXH3_freeState(state);
        return 0;
}
*/

void main() {
  group('Test streaming API against known values', () {
    late XXH3State hashStream;

    setUp(() {
      hashStream = xxh3Stream();
    });

    test('Hashing "Hello, world!"', () {
      hashStream.update(utf8.encode('Hello, world!'));
      expect(hashStream.digest(), equals(kXXH3StreamHelloWorld));
    });

    test('Hashing "Hello, world!" twice', () {
      hashStream.update(utf8.encode('Hello, world!'));
      hashStream.update(utf8.encode('Hello, world!'));
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

    // test('Hashing "Hello, world!" 512 times', () {
    //   for (int i = 0; i < 512; i++) {
    //     hashStream.update(utf8.encode('Hello, world!'));
    //   }
    //
    //   expect(hashStream.digest(), equals(kXXH3StreamHelloWorldTwice));
    // });
  });

  group('digest and digestString should be idempotent', () {
    late XXH3State hashStream;

    setUp(() {
      hashStream = xxh3Stream();
    });

    test('digest', () {
      hashStream.update(utf8.encode('Hello, world!'));
      hashStream.update(utf8.encode('Hello, world!'));
      expect(hashStream.digest(), equals(kXXH3StreamHelloWorldTwice));
      expect(hashStream.digest(), equals(kXXH3StreamHelloWorldTwice));
    });

    test('digestString', () {
      hashStream.update(utf8.encode('Hello, world!'));
      hashStream.update(utf8.encode('Hello, world!'));
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
}
