library xxh3;

import 'dart:typed_data';

import 'package:xxh3/src/util.dart';
import 'package:xxh3/src/xxh3.dart';
import 'package:xxh3/xxh3.dart';

const kXXH3BufferStripes = kXXH3BufferSize ~/ kStripeLength;

// When we move to Dart 3 support, this can be collected into a final class.

abstract class XXH3State {
  const XXH3State._();

  /// Create an [XXH3State]. This automatically calls [reset] to ensure that the
  /// state is initialized. Calling [reset] again isn't a no-op, but it
  /// shouldn't alter any of the output.
  ///
  /// See [reset] for details about initialization.
  factory XXH3State.create({Uint8List? secret, int? seed}) =>
      _XXH3State.create(secret: secret, seed: seed);

  /// Reset the [XXH3State]. This is called automatically on [create].
  ///
  /// - If [secret] *and* [seed] are specified; they are used as-is.
  /// - If just the [secret] is provided; it is used with the default [seed] (0)
  ///   provided that it is valid.
  /// - If just the [seed] is provided; it is either used with the default
  ///   [secret] or the existing secret is re-initialized with the seed.
  /// - If neither the [secret] nor the [seed] are provided; default values are
  ///   used for both.
  void reset({Uint8List? secret, int? seed});

  /// Update the [XXH3State] with the [input] data.
  void update(Uint8List input);

  /// Digest the [XXH3State] and produce a resulting 64-bit XXH3 hash value.
  ///
  /// Calling [digest] does not affect the [XXH3State], allowing you to digest,
  /// update and digest again.
  int digest();

  /// A convenience wrapper for [digest] that returns the result, formatted as
  /// an unsigned hexadecimal string.
  String digestString() =>
      BigInt.from(digest()).toUnsigned(64).toRadixString(16);
}

class _XXH3State extends XXH3State {
  final Uint64List _acc = Uint64List(8);

  /// The secret provided for [_resetWithSecret] or [_resetWithSecretAndSeed].
  ByteData? _extSecret;

  /// The secret generated for [_resetWithSeed].
  ByteData? _customSecret;

  ByteData get _secret {
    if (_extSecret != null) return _extSecret!;
    if (_customSecret != null) return _customSecret!;
    return kSecretView;
  }

  int? _seed;

  // BEGIN: initialized in _resetInternal.
  /// An internal buffer ([kXXH3BufferSize] bytes) for incremental
  /// hashing of small payloads.
  late Uint8List _buffer;

  late int _buffered = 0;
  late int _secretLimit = 0;
  late int _nbStripesPerBlock = 0;
  late int _nbStripesSoFar = 0;
  late int _totalLen;
  // END: initialized in _resetInternal.

  bool _initialized = false;

  _XXH3State._() : super._();

  factory _XXH3State.create({Uint8List? secret, int? seed}) {
    final state = _XXH3State._();
    state.reset(secret: secret, seed: seed);
    return state;
  }

  void _resetInternal(int? seed, ByteData? secret) {
    if (secret != null) {
      // Ensure that the secret is valid if it was specified.
      validateSecret(secret);
    }

    resetAccumulator(_acc);
    _seed = seed;
    _extSecret = secret;

    // Initialize all of the 'late' values.
    _buffer = Uint8List(kXXH3BufferSize);
    _buffered = 0;
    _secretLimit = _secret.lengthInBytes - kStripeLength;
    _nbStripesPerBlock = _secretLimit ~/ kSecretConsumeRate;
    _nbStripesSoFar = 0;
    _totalLen = 0;

    // Indicate that the state has been initialized at least once.
    _initialized = true;
  }

  // These reset functions are designed to mirror those in the XXH3 repository
  // directly (even if they are abstracted away in the publicly exposed [reset]
  // function to make this more idiomatic).

  void _reset() => _resetInternal(null, kSecretView);
  void _resetWithSecret(ByteData secret) => _resetInternal(null, secret);
  void _resetWithSeed(int seed) {
    if (seed == 0) return _reset();
    if (seed != _seed || _extSecret != null) {
      _customSecret = initCustomSecret(seed);
    }
    _resetInternal(seed != 0 ? seed : null, null);
  }

  void _resetWithSecretAndSeed(ByteData secret, int seed) {
    _resetInternal(seed, secret);
    _seed = seed; // Ensure that the seed is used, even if it's 0.
  }

  @override
  void reset({Uint8List? secret, int? seed}) {
    if (secret != null && seed != null) {
      _resetWithSecretAndSeed(ByteData.view(secret.buffer), seed);
    } else if (secret != null) {
      _resetWithSecret(ByteData.view(secret.buffer));
    } else if (seed != null) {
      _resetWithSeed(seed);
    } else {
      _reset();
    }
  }

  int _consumeStripes(
      Uint64List acc, ByteData input, int nbStripes, ByteData secret) {
    ByteData initialSecret =
        ByteData.sublistView(secret, _nbStripesSoFar * kSecretConsumeRate);
    int consumed = 0;

    // Process full blocks.
    if (nbStripes >= (_nbStripesPerBlock - _nbStripesSoFar)) {
      // Process the initial partial block.
      int stripesThisIter = _nbStripesPerBlock - _nbStripesSoFar;

      do {
        accumulate(acc, input, initialSecret,
            inputOffset: consumed, stripes: stripesThisIter);
        scrambleAccumulator(acc, ByteData.sublistView(secret, _secretLimit));
        consumed += stripesThisIter * kStripeLength;
        nbStripes -= stripesThisIter;
        // Then continue with the full block size.
        stripesThisIter = _nbStripesPerBlock;
        initialSecret = secret;
      } while (nbStripes >= _nbStripesPerBlock);
      _nbStripesSoFar = 0;
    }

    // Process a partial block.
    if (nbStripes > 0) {
      accumulate(acc, input, secret, inputOffset: consumed, stripes: nbStripes);
      consumed += nbStripes * kStripeLength;
      _nbStripesSoFar += nbStripes;
    }

    return consumed;
  }

  @override
  void update(Uint8List input) {
    if (!_initialized) {
      // This shouldn't be possible.
      throw StateError(
          "Cannot 'update' the XXH3 digest before it has been initialized.");
    }

    // Determine the input length. If it's zero, there's nothing else to do,
    // otherwise add it to the number of processed bytes.
    int inputLength = input.lengthInBytes;
    if (inputLength == 0) return;
    _totalLen += inputLength;

    // If we can fit it in the buffer, just add it there and wait for more.
    if (inputLength <= kXXH3BufferSize - _buffered) {
      _buffer.setAll(_buffered, input);
      _buffered += inputLength;
      return;
    }

    // The amount of input data that we have consumed,
    int consumed = 0;

    // We proceed here only when we can't fit the entirety of the new data into
    // the buffer; fill the buffer to completion, then consume the buffer.
    if (_buffered > 0 && _buffered < kXXH3BufferSize) {
      // Get the number of bytes available in the buffer, then apply that many
      // bytes from the input into the buffer.
      int availableBuffer = kXXH3BufferSize - _buffered;
      _buffer.setAll(_buffered, input.sublist(0, availableBuffer));
      consumed += availableBuffer;
      _consumeStripes(
        _acc,
        ByteData.view(_buffer.buffer),
        kXXH3BufferStripes,
        _secret,
      );
      _buffered = 0;
    }

    // Consume any complete stripes directly - if they cannot fit in the buffer.
    int remaining = inputLength - consumed;
    if (remaining > kXXH3BufferSize) {
      int nbStripes = (remaining - 1) ~/ kStripeLength;
      consumed += _consumeStripes(
        _acc,
        ByteData.sublistView(input, consumed),
        nbStripes,
        _secret,
      );
      // Copy the last stripe of input into the buffer.
      _buffer.setAll(
        _buffer.lengthInBytes - kStripeLength,
        Uint8List.sublistView(input, consumed - kStripeLength),
      );
    }

    // Buffer the last part of the input.
    remaining = inputLength - consumed;
    _buffer.setAll(0, Uint8List.sublistView(input, remaining));
    _buffered += remaining;
  }

  _digestLong() {
    final lastStripe = Uint8List(kStripeLength);
    ByteData lastStripePtr;

    // Clone the accumulator to avoid mutating the state.
    final acc = Uint64List.fromList(_acc);

    if (_buffered >= kStripeLength) {
      final nbStripes = (_buffered - 1) ~/ kStripeLength;
      int stripesSoFar = _nbStripesSoFar;
      _consumeStripes(acc, ByteData.view(_buffer.buffer), nbStripes, _secret);
      _nbStripesSoFar = stripesSoFar; // Reset _nbStripesSoFar.
      lastStripePtr = ByteData.sublistView(_buffer, _buffered - kStripeLength);
    } else {
      final catchupSize = kStripeLength - _buffered;
      lastStripe.setAll(0,
          Uint8List.sublistView(_buffer, _buffer.lengthInBytes - catchupSize));
      lastStripe.setAll(catchupSize, Uint8List.sublistView(_buffer, _buffered));
      lastStripePtr = ByteData.view(lastStripe.buffer);
    }

    // Last stripe.
    accumulate512(acc, lastStripePtr, _secret, secretOffset: _secretLimit - 7);
  }

  @override
  int digest() {
    if (_totalLen > kXXH3MidSizeMax) {
      _digestLong();
      return _mergeAccs(_acc, _secret, _totalLen * kXXHPrime64_1,
          secretOffset: 11);
    }

    // If we're digesting a short input, just use the appropriate XXH3 function
    // directly.
    if (_seed != null) {
      return xxh3(Uint8List.sublistView(_buffer, 0, _totalLen), seed: _seed!);
    }

    return xxh3(
      Uint8List.sublistView(_buffer, 0, _totalLen),
      secret: Uint8List.view(_secret.buffer, 0, _secretLimit + kStripeLength),
    );
  }
}

int _mix2Accs(Uint64List acc, ByteData secret,
        {int accOffset = 0, int secretOffset = 0}) =>
    mul128Fold64(
      acc[accOffset + 0] ^ readLE64(secret, secretOffset),
      acc[accOffset + 1] ^ readLE64(secret, secretOffset + 8),
    );

int _mergeAccs(Uint64List acc, ByteData secret, int start,
    {int secretOffset = 0}) {
  int result = start;

  for (int i = 0; i < 4; i++) {
    result += _mix2Accs(
      acc,
      secret,
      accOffset: 2 * i,
      secretOffset: (16 * i) + secretOffset,
    );
  }

  return xXH3Avalanche(result);
}
