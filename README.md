FreeBSD port for Tensorflow 1.15

This is the development repository for
[science/libtensorflow1](https://www.freshports.org/science/libtensorflow1/).

# Usage

So the easiest way to install it is `pkg install libtensorflow1`.

To install the dev release:

```
cd /usr/ports/science
git clone https://github.com/psa/libtensorflow1-freebsd-port libtensorflow1
cd libtensorflow1
make package
```

This takes a long time to build (~90 minutes with 4 Xeon E31275 @ 3.40GHz
cores) and 8+ GiB of RAM.
