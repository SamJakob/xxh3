import 'dart:convert' show utf8;

import 'package:xxh3/xxh3.dart';

void main() {
  // Get the string as UTF-8 bytes.
  final helloWorldBytes = utf8.encode("Hello, world!");

  // Use XXH3 to hash the byte array (returns an int).
  // XXH3 is a 64-bit hash, so the value is returned in the
  // form of an unsigned 64-bit integer.
  final int digest = xxh3(helloWorldBytes);
  print(digest); // -881777603154417559

  // Alternatively, in version 1.1.0+, you can use the
  // xxh3String convenience method to get a hexadecimal
  // string representation of the hash.
  final String hexDigest = xxh3String(helloWorldBytes);
  print(hexDigest); // f3c34bf11915e869

  // Similarly, in version 1.2.0+, you can use the
  // streaming API to process your data in blocks.
  final hashStream = xxh3Stream();
  hashStream.update(helloWorldBytes);
  print(hashStream.digest());
  print(hashStream.digestString());

  // See the examples and documentation for more...
}
