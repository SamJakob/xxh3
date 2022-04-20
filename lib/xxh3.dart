import 'package:xxh3/src/xxh3.dart';

/// Perform an XXH3 hash of the input data.
/// The result is returned as an int, which is a signed 64-bit integer.
int xxh3(List<int> input) {
  return xXH3_64bitsConst(input);
}
