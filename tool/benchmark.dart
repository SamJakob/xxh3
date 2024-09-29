import 'dart:io';
import 'dart:typed_data';

import 'package:xxh3/xxh3.dart';

const kBatchSize = 100;
const kDataSize = 64 * 1024;

void main() {
  final args = [];

  final bytes =
      args.isEmpty ? Uint8List(kDataSize) : File(args.first).readAsBytesSync();

  final batchResults = <double>[];

  for (var j = 0; j < kBatchSize; j++) {
    print('== Batch ${j + 1} of $kBatchSize ==');

    final N = 5000;
    final sw = Stopwatch()..start();
    for (var i = 0; i < N; i++) {
      xxh3(bytes);
    }
    final totalNs = sw.elapsedMicroseconds * 1000;
    final nsPerIteration = totalNs / N;
    final nsPerByte = nsPerIteration / bytes.lengthInBytes;
    batchResults.add(nsPerByte);

    print('  -> $nsPerByte ns/byte');
  }

  print('');
  print('== Summary ==');

  print('Data size: $kDataSize bytes');

  final averageNsPerByte = batchResults.reduce((a, b) => a + b) / kBatchSize;
  print('Average: $averageNsPerByte ns/byte');

  final nsPerGB = averageNsPerByte * 1024 * 1024 * 1024; // kB -> mB -> GB
  final gigabytesPerNs = 1 / nsPerGB;
  final gigabytesPerSecond = gigabytesPerNs * 1e9;
  print('Average: ${gigabytesPerSecond.toStringAsFixed(2)} GB/s');
}
