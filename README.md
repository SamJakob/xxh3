# dart-xxh3
An extremely quick and dirty XXH3 implementation in Dart.

This pretty much exists solely to make XXH3 'work' in some of my projects, it
sure ain't pretty. At some point I may come back and clean this up.

NOTE: This will probably only work for dart native environments (so Flutter and
Dart native executables). I made assumptions about integer sizes, etc.,

## Credit
Parts of this code may be reproduced or based on the following sources:
- https://github.com/Cyan4973/xxHash/
- https://github.com/OpenHFT/Zero-Allocation-Hashing/blob/ea/src/main/java/net/openhft/hashing/XXH3.java
- https://github.com/chys87/constexpr-xxh3
