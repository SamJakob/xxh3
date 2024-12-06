# Package development notes

## Updating the default XXH3 secret file (`lib/src/secret.dart`)

The default secret used by the XXH3 algorithm is defined in [`tool/generate_secret.dart`](/tool/generate_secret.dart)
which, when executed, generates [`lib/src/secret.dart`](/lib/src/secret.dart).

This should never have to change, but if for some reason the default secret in
the official XXH3 implementation changes, this Dart implementation should be
updated to reflect that.

To change the default secret, modify the code in [`tool/generate_secret.dart`](/tool/generate_secret.dart)
accordingly. Then run the following to write the new secret to the library file:

```bash
dart tool/generate_secret.dart > ./lib/src/secret.dart
dart format ./lib/src/secret.dart
```
