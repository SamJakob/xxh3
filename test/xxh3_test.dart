import 'dart:io';

import 'package:test/test.dart';
import 'package:xxh3/xxh3.dart';

import 'common_known_answers.dart';
import 'utils.dart';
import 'xxh3_stream_test.dart';

void main() {
  group('Test against known hash values', () {
    testKnownAnswers(xxh3);
  });

  test(
    'Test hashing example/example_pubspec.yml against known value',
    () async {
      final file = File('example/example_pubspec.yml');
      expect(xxh3(await file.readAsBytes()), kXXH3StreamExamplePubspecFile);
    },
  );

  group('xxh3String', () {
    test('Using xxh3String produces an expected unsigned 64-bit hex value', () {
      expect(
        xxh3String(stringBytes('Hello, world!')),
        equals('f3c34bf11915e869'),
      );
    });
  });
}
