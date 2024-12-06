import 'dart:io';
import 'dart:typed_data';

import 'package:xxh3/xxh3.dart';

const kBatchSize = 100;
const kDataSize = 64 * 1024;

void main() {
  final args = <String>[];

  final bytes =
      args.isEmpty ? Uint8List(kDataSize) : File(args.first).readAsBytesSync();

  final batchResults = <double>[];

  for (var j = 0; j < kBatchSize; j++) {
    stdout.writeln('== Batch ${j + 1} of $kBatchSize ==');

    const N = 5000;
    final sw = Stopwatch()..start();
    for (var i = 0; i < N; i++) {
      xxh3(bytes);
    }
    final totalNs = sw.elapsedMicroseconds * 1000;
    final nsPerIteration = totalNs / N;
    final nsPerByte = nsPerIteration / bytes.lengthInBytes;
    batchResults.add(nsPerByte);

    stdout.writeln('  -> $nsPerByte ns/byte');
  }

  stdout
    ..writeln('')
    ..writeln('== Summary ==')
    ..writeln('Data size: $kDataSize bytes');

  final averageNsPerByte =
      batchResults.reduce((final a, final b) => a + b) / kBatchSize;
  stdout.writeln('Average: $averageNsPerByte ns/byte');

  final nsPerGB = averageNsPerByte * 1024 * 1024 * 1024; // kB -> mB -> GB
  final gigabytesPerNs = 1 / nsPerGB;
  final gigabytesPerSecond = gigabytesPerNs * 1e9;
  stdout.writeln('Average: ${gigabytesPerSecond.toStringAsFixed(2)} GB/s');
}
