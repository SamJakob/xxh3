## Credits

- Thank you to [@mraleph](https://github.com/mraleph) for the significant (10x)
  performance improvements introduced by [PR #4](https://github.com/SamJakob/xxh3/pull/4).

- Inspiration was drawn from the [OpenHFT Zero-Allocation-Hashing Java implementation](https://github.com/OpenHFT/Zero-Allocation-Hashing/blob/ea/src/main/java/net/openhft/hashing/XXH3.java).
  Particularly, with respect to implementing the avalanche and mixing functions.

- Additionally, chys87's `constexpr-xxh3` implementation was helpful
  as a particularly readable example for understanding the algorithm:
  https://github.com/chys87/constexpr-xxh3

- ...and of course Cyan4973's original XXH3 implementation:
  https://github.com/Cyan4973/xxHash/
