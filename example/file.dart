import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:xxh3/xxh3.dart';

Future<void> main() async {
  final File file = File("example/example_pubspec.yml");

  XXH3State stream;

  print('=> Stream API');
  stream = xxh3Stream();
  await file.openRead().map(Uint8List.fromList).forEach(stream.update);
  print(stream.digest());
  print(stream.digestString());
  print('');

  // The hash is the same - even if the data is delivered to 'update'
  // differently.
  print('=> Stream API (chunked)');
  stream = xxh3Stream();
  await file
      .openRead()
      .chunked(kXXH3StreamBufferSize)
      .map(Uint8List.fromList)
      .forEach(stream.update);
  print(stream.digest());
  print(stream.digestString());
  print('');

  // Notice that the stream API yields the same value as calling the buffer API.
  print('=> Buffer API (chunked)');
  final data = await file.readAsBytes();
  print(xxh3(data));
  print(xxh3String(data));
  print('');
}

/// An extension that adds the [chunked] method to a [Stream] of [List]s, to
/// allow dividing that [Stream] of (potentially) arbitrarily sized [List]s into
/// a stream of fixed sized [List]s.
extension ChunkedStream<T> on Stream<List<T>> {
  /// Convert the stream to a chunked stream, where each chunk is of the given
  /// [size]. The size of each chunk must be at least one, but the size may be
  /// any number larger than one (if the stream is finished before a chunk is
  /// finished, that chunk is returned as-is).
  Stream<List<T>> chunked(final int size) async* {
    if (size < 1) {
      throw RangeError.range(
        size,
        1,
        null,
        'size',
        'Chunk size is invalid',
      );
    }

    // Prepare the first chunk to be yielded. (This will be yielded as-is if the
    // stream is empty).
    List<T> chunk = [];

    // Each time the stream yields a List<T>...
    await for (final List<T> data in this) {
      var consumed = 0;

      // Whilst we still have data to consume from this current List<T>...
      while (consumed < data.length) {
        // ...fill up the chunk we're working on by computing how many items
        // (e.g., bytes) we need to fill it with, then taking that many from the
        // current List<T> and adding that to our offset (consumed) - so we know
        // where to start filling the next chunk from.
        final next = size - chunk.length;
        chunk.addAll(data.skip(consumed).take(next));
        consumed += next;

        // If we've created a full chunk, yield it and start the next one.
        if (chunk.length == size) {
          yield chunk;
          chunk = [];
        }
      }
    }

    // Finally, yield the last chunk - even if it isn't yet completed.
    yield chunk;
  }
}
