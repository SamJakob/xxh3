/// A Dart port of the XXH3 hashing function.
///
/// The original implementation by Cyan4973 is available on GitHub:
/// https://github.com/Cyan4973/xxHash/
///
/// The algorithm's specification can be found, in Markdown, as part of the
/// xxHash repository:
/// https://github.com/Cyan4973/xxHash/blob/dev/doc/xxhash_spec.md
library xxh3;

import 'dart:typed_data';

import 'package:xxh3/src/constants.dart';
import 'package:xxh3/src/xxh3_buffer.dart';
import 'package:xxh3/src/xxh3_stream.dart';

export 'package:xxh3/src/constants.dart'
    show kSecretSizeMin, kXXH3SmallDataSize, kXXH3StreamBufferSize;
export 'package:xxh3/src/xxh3_stream.dart' show XXH3State;

/// When hashing inputs of length greater than 240, the [HashLongFunction]
/// is used. The default is [kXXH3HashLongFunction64Bit].
///
/// {@category Buffer API}
typedef HashLongFunction = int Function(
  ByteData input,
  int seed,
  ByteData secret,
);

/// The default HashLongFunction from xxHash.
/// See [HashLongFunction].
///
/// {@category Buffer API}
const HashLongFunction kXXH3HashLongFunction64Bit = xxh3_64HashLongInternal;

/// Perform an XXH3 hash of the input data.
/// The input data is provided as a [Uint8List] to avoid having to
/// perform conversions internally.
///
/// A typical usage example is as follows:
///
/// ```dart
/// // Get some binary data (as a Uint8List)
/// final data = utf8.encode('Hello, world!');
///
/// // Use XXH3 to hash the byte array (returns an int).
/// // XXH3 is a 64-bit hash, so the value is returned in the
/// // form of a 64-bit integer.
/// final int digest = xxh3(data);
/// print(digest); // -881777603154417559
/// ```
///
/// {@template uint8list}
/// To convert a [List] of [int]s to a [Uint8List], you can use
/// [Uint8List.fromList].
/// {@endtemplate}
///
/// {@template int_representation}
/// The resulting 64-bit value is returned as an [int].
///
/// **Note:** in Dart, all [int]s are *represented as* signed, whereas an XXH3
/// (or other) hash would typically be represented as unsigned. This is just a
/// different representation of the same data. You can use [BigInt] to generate
/// your own 64-bit unsigned representation (at slightly more cost in terms of
/// CPU cycles) - as the [xxh3String] function does internally.
/// {@endtemplate}
///
/// {@template custom_secret}
/// Optionally, a [secret] may be specified (if one is not specified, the
/// default secret is used). If a secret is specified, it must be greater, in
/// length, than [kSecretSizeMin].
///
/// Per XXH3, the secret **MUST** look like a bunch of random bytes as the
/// quality of the secret impacts the dispersion of the hash algorithm.
/// "Trivial" or structured data such as repeated sequences or a text
/// document should be avoided.
/// {@endtemplate}
///
/// The [seed] may be customized (the default value of the seed is 0).
/// **Note that** if the seed is customized, the secret is ignored when the data
/// being hashed is smaller than the [kXXH3SmallDataSize].
///
/// A custom [HashLongFunction] may also be specified. By default,
/// this is the [kXXH3HashLongFunction64Bit] which is the HashLongFunction
/// included with xxHash.
///
/// {@category Buffer API}
int xxh3(
  final Uint8List input, {
  final Uint8List? secret,
  final int seed = 0,
  final HashLongFunction hashLongFunction = kXXH3HashLongFunction64Bit,
}) =>
    xxh3_64Internal(
      input: input,
      seed: seed,
      hashLongFunction: hashLongFunction,
      secret: secret,
    );

/// A convenience wrapper for [xxh3] that returns the result, formatted as an
/// unsigned hexadecimal string.
///
/// A typical usage example is as follows:
///
/// ```dart
/// // Get some binary data (as a Uint8List)
/// final data = utf8.encode('Hello, world!');
///
/// // Use XXH3 to hash the byte array and get the
/// result as an unsigned hex value (returns a string).
/// final int digest = xxh3String(data);
/// print(digest); // f3c34bf11915e869
/// ```
///
/// {@category Buffer API}
String xxh3String(
  final Uint8List input, {
  final Uint8List? secret,
  final int seed = 0,
  final HashLongFunction hashLongFunction = kXXH3HashLongFunction64Bit,
}) =>
    BigInt.from(
      xxh3(
        input,
        secret: secret,
        seed: seed,
        hashLongFunction: hashLongFunction,
      ),
    ).toUnsigned(64).toRadixString(16);

/// Create an XXH3 stream ([XXH3State]). This state can be updated
/// ([XXH3State.update]) with data as many times as desired, then digested with
/// [XXH3State.digest] to compute the final hash.
///
/// A typical usage example is as follows:
///
/// ```dart
/// // Get some binary data (as a Uint8List)
/// // final data = utf8.encode('Hello, world!');
///
/// // Create a new hash state.
/// final hash = xxh3Stream();
///
/// // Write the data into the hash state.
/// // This can be called multiple times (e.g., to stream a large file in
/// // chunks).
/// hash.update(data);
///
/// // Compute a digest (notice that this has the same output as xxh3 and
/// // xxh3String, respectively).
/// hash.digest(); // -881777603154417559
/// hash.digestString(); // f3c34bf11915e869
/// ```
///
/// Alternatively, an example that streams in a file with `openRead` is:
///
/// ```dart
/// final File file = File("/path/to/your/file");
/// final hash = xxh3Stream(); // Create a new hash state.
///
/// // Open a file for reading, it returns a stream of lists of bytes (i.e., a
/// // stream of chunks of the file).
/// final Stream<List<int>> fileChunkStream = file.openRead();
///
/// // Map the stream of List<int> chunks to a stream of Uint8List chunks.
/// // (They are equivalent, however hash.update works on Uint8Lists, not
/// // List<int>s).
/// final Stream<Uint8List> typedChunkStream =
///       fileChunkStream.map((chunk) => Uint8List.fromList(chunk));
///
/// // For each chunk, update the hash state.
/// await typedChunkStream.forEach((typedChunk) => hash.update(typedChunk));
///
/// // Digest the hash.
/// hash.digest(); // (returns a signed 64-bit integer).
/// hash.digestString(); // (returns an unsigned hex string).
/// ```
///
/// Of course, the above is broken down for clarity. It can be made much more
/// concise:
///
/// ```dart
/// final File file = File("/path/to/your/file");
/// final hash = xxh3Stream();
///
/// // Update the hash as chunks from the file are obtained.
/// await file.openRead().map(Uint8List.fromList).forEach(hash.update);
///
/// // Digest the hash.
/// hash.digest(); // (returns a signed 64-bit integer).
/// hash.digestString(); // (returns an unsigned hex string).
/// ```
///
/// {@macro uint8list}
///
/// {@macro custom_secret}
///
/// The [seed] may be customized (the default value of the seed is 0).
///
/// **Note:** the semantics of defining a secret and/or a seed can be different
/// for [xxh3Stream] than they are for [xxh3]. For instance, because the length
/// of the data is potentially unknown when working with a stream, the streaming
/// API does not opt to ignore a custom secret for small data like [xxh3] does.
///
/// The behavior has been implemented here consistently with the xxHash library.
///
/// {@category Stream API}
XXH3State xxh3Stream({final Uint8List? secret, final int? seed}) =>
    XXH3State.create(secret: secret, seed: seed);
