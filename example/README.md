To hash a string:
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
  
}
```

An integer is returned by the library as XXH3 is a 64-bit hash.

For an example of how to convert the resulting integer to a
Uint8List (byte array), see the following example:
```dart
import 'dart:convert' show utf8;
import 'dart:typed_data';

import 'package:xxh3/xxh3.dart';

void main() {

  // Get the string as UTF-8 bytes.
  final bytes = utf8.encode("Hello, world!");
  
  // Create a ByteData object for 8 bytes (64-bit integer),
  // write the value in as an unsigned 64-bit integer and
  // then obtain the underlying buffer from the ByteData
  // object as a Uint8List.
  final digest = ByteData(8)
    ..setUint64(0, xxh3(Uint8List.fromList(bytes)))
    ..buffer.asUint8List(0);
  
}
```