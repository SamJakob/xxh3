# dart-xxh3

[![Pub Publisher](https://img.shields.io/pub/publisher/xxh3?style=for-the-badge) ![Pub Version](https://img.shields.io/pub/v/xxh3?style=for-the-badge)](https://pub.dev/packages/xxh3) [![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/samjakob/xxh3/test_and_coverage.yml?branch=master&style=for-the-badge)](https://github.com/SamJakob/xxh3/actions/workflows/test_and_coverage.yml) [![Codecov](https://img.shields.io/codecov/c/github/SamJakob/xxh3?style=for-the-badge)](https://app.codecov.io/gh/SamJakob/xxh3) [![MIT License](https://img.shields.io/github/license/SamJakob/xxh3?style=for-the-badge)](https://github.com/SamJakob/xxh3/blob/master/LICENSE)

Port of the [XXH3 hashing algorithm](https://github.com/Cyan4973/xxHash/) in
Dart.

```dart
import 'dart:convert' show utf8;
import 'dart:typed_data';

import 'package:xxh3/xxh3.dart';

void main() {

  // Get the string as UTF-8 bytes.
  final bytes = utf8.encode("Hello, world!");
  
  // Use XXH3 to hash the byte array (returns an int).
  // XXH3 is a 64-bit hash, so the value is returned in the
  // form of an unsigned 64-bit integer.
  final int digest = xxh3(Uint8List.fromList(bytes));
  print(digest);
  
  // See the examples and documentation for more...
  
}
```

Refer to the [Example tab](https://pub.dev/packages/xxh3/example) for
a 'quick start guide', or for more details refer to the
[API Documentation](https://pub.dev/documentation/xxh3/latest/).

As it stands, this is a port written entirely in Dart. It should perform fairly
well, but I have not benchmarked it as the main goal for this package is to
have a compatible hash implementation in Dart. If better performance is needed,
this could probably serve as a fallback and `dart:ffi` could be used to call
native code for better performance.

This uses native integers for performance reasons, so this will not provide
correct results for Dart web. If there is demand for this, that could probably
be rectified.
