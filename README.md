# xxh3 (for Dart)

[![Pub Publisher](https://img.shields.io/pub/publisher/xxh3?style=for-the-badge) ![Pub Version](https://img.shields.io/pub/v/xxh3?style=for-the-badge)](https://pub.dev/packages/xxh3) [![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/samjakob/xxh3/test_and_coverage.yml?branch=master&style=for-the-badge)](https://github.com/SamJakob/xxh3/actions/workflows/test_and_coverage.yml) [![Codecov](https://img.shields.io/codecov/c/github/SamJakob/xxh3?style=for-the-badge)](https://app.codecov.io/gh/SamJakob/xxh3) [![MIT License](https://img.shields.io/github/license/SamJakob/xxh3?style=for-the-badge)](https://github.com/SamJakob/xxh3/blob/master/LICENSE)

Port of the [XXH3 hashing algorithm](https://github.com/Cyan4973/xxHash/) in
Dart.

Presently, only the 64-bit version of XXH3 (XXH3-64) is supported.
Please feel free to [open a GitHub issue](https://github.com/SamJakob/xxh3/issues/new) if you need support for XXH3-128.

```dart
import 'dart:convert' show utf8;
import 'dart:typed_data';

import 'package:xxh3/xxh3.dart';

void main() {
  // Get the string as UTF-8 bytes.
  final helloWorldBytes = utf8.encode("Hello, world!");
  
  // Use XXH3 to hash the byte array (returns an int).
  // XXH3 is a 64-bit hash, so the value is returned in the
  // form of a 64-bit integer.
  final int digest = xxh3(helloWorldBytes);
  print(digest); // -881777603154417559
  
  // Alternatively, in version 1.1.0+, you can use the
  // xxh3String convenience method to get a hexadecimal
  // string representation of the hash.
  final String hexDigest = xxh3String(helloWorldBytes);
  print(hexDigest); // f3c34bf11915e869

  // Similarly, in version 1.2.0+, you can use the
  // stream API to process your data in blocks.
  final hashStream = xxh3Stream();
  hashStream.update(helloWorldBytes);
  print(hashStream.digest()); // -881777603154417559
  print(hashStream.digestString()); // f3c34bf11915e869
  
  // See the examples and documentation for more...
}
```

Refer to the [Example tab](https://pub.dev/packages/xxh3/example) for
a 'quick start guide', or for more details refer to the
[API Documentation](https://pub.dev/documentation/xxh3/latest/).

## Performance

As it stands, this is a port written entirely in Dart. At the time of writing
it has a throughput of ~0.29 ns/byte (3.16 GB/s) on an Apple M-series processor
in JIT mode or ~0.28 ns/byte (3.23 GB/s) in AOT mode.

The streaming APIs currently have no further optimization and are therefore
about 0.4-0.6ns/byte slower than the buffered APIs.

You can run the benchmarks yourself on your machine with the following commands:

```bash
# For JIT mode
dart run tool/benchmark.dart
```

```bash
# For AOT mode
dart compile exe tool/benchmark.dart -o benchmark
./benchmark
```

If better performance is needed, `dart:ffi` can be used to call the original
C implementation. This is not currently implemented in this package, but feel
free to open a ticket on GitHub if you would like this.

This assumes that the `int` type is a 64-bit integer, so this will likely not
provide correct results for Dart web (JavaScript), where after 2^53, integers
become floating point numbers. If there is demand for this, that could probably
be addressed by using a custom integer type or a JavaScript `Uint8Array`.

WebAssembly could also be a potential workaround, but I have not investigated
this yet.
