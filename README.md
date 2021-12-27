FreeBSD port for Tensorflow 1.15

This provides an easy to use copy of *science/libtensorflow1* until the port is
committed to the repository.

You can follow the port progress in [bug
260694](https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=260694)

# Usage

```
cd /usr/ports/science
git clone https://github.com/psa/libtensorflow1-freebsd-port libtensorflow1
cd libtensorflow1
make package
```

This takes a long time to build (~90 minutes with 4 Xeon E31275 @ 3.40GHz
cores) and 8 GiB of RAM.

# Binaries

Binaries can be found under [releases](https://github.com/psa/libtensorflow1-freebsd-port/releases).

If you're interested in providing binaries for a platform that's not currently supported, please file a bug and I'll add permissions.
