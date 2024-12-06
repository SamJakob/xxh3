This API requires the data to be buffered up-front - e.g., in the form of a
[Uint8List][].

If all you need is a digest and your data is typically small (i.e., under
[kXXH3SmallDataSize][]), you will almost certainly want the buffer API for
performance reasons (it is also simpler!).

You can use the [xxh3][] function as a Dart equivalent for the following
xxHash C functions:

- `XXH3_64bits`
- `XXH3_64bits_withSecret`
- `XXH3_64bits_withSeed`
- `XXH3_64bits_withSecretandSeed`

Any implied semantics of calling one of the above functions are automatically
handled based on which parameters are supplied or not supplied; e.g., calling
[xxh3][] with just a secret and not specifying a seed is equivalent to calling
`XXH3_64bits_withSecret` in C, and so on...

[Uint8List]: https://api.dart.dev/stable/dart-typed_data/Uint8List-class.html
[kXXH3SmallDataSize]: https://pub.dev/documentation/xxh3/latest/xxh3/kXXH3SmallDataSize-constant.html
[xxh3]: https://pub.dev/documentation/xxh3/latest/xxh3/xxh3.html
