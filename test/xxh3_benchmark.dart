import 'dart:io';
import 'dart:typed_data';

import 'package:xxh3/xxh3.dart';

void main(List<String> args) {
  final bytes =
      args.isEmpty ? Uint8List(64 * 1024) : File(args.first).readAsBytesSync();

  for (var j = 0; j < 2; j++) {
    final N = 5000;
    final sw = Stopwatch()..start();
    for (var i = 0; i < N; i++) {
      xxh3(bytes);
    }
    final totalNs = sw.elapsedMicroseconds * 1000;
    final nsPerIteration = totalNs / N;
    final nsPerByte = nsPerIteration / bytes.lengthInBytes;

    print('$nsPerByte ns/byte');
  }
}
