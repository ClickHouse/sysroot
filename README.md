# Files For Cross-Compilation

To do cross-compiling, "toolchain" has to be used.

Typical toolchain contains:
- header files for the target platform for "default" libraries like libc, c++ standard library, etc;
- header files for the libraries related to compiler builtins (known as `compiler-rt` or `libgcc`, sometimes including a library for exception handling support);
- binaries `.a`, `.so` and similar for "default" libraries;
- binaries for "startfiles" like `crt1.o` that contain entry point, initialization and deinitialization routines relevant to the libc;
- the binaries of cross-compiler, cross-linker, cross-assembler, `ar` and `ranlib` and possibly other `binutils` - the binaries that run on host platform but generates artifacts for the target platform;

Toolchain is usually distributed as a tarball and is quite large, in order of hundreds MB.
It contains an amalgamation of tools, libraries and binaries for all the needs: C, C++, Fortran, CUDA...

We don't really need all of this amalgamation for the following reason:
- we don't need cross-compiler and other tools, because we use LLVM infrastructure (clang, lld, llvm-ar, ...) and it supports cross-compilation by default;
- we don't need C++ headers and libraries because we include libc++, libc++abi, LLVM's libunwind as a source code and compile it from sources during build process;
- we definitely don't need Fortran headers;

The idea is to strip down the "toolchain" as much as possible and provide it as a submodule instead of tarball.
Actually it's not longer a "toolchain", it's just a collection of libc-related libraries and a few files for compiler builtins.

This gives us the following advantages:
- more easy to add new platforms (no need to search for complete toolchain, just copy the relevant files from the OS image);
- better understanding what's going on - only the relevant files included;
- avoid risks of supply-chain attacks;
- allow to use custom sysroot even for default (non-cross) build to get reproducible, hermetic builds;
- opens up for experiment of building the libc from sources;
- simplify using musl-libc instead of glibc.

This repository contains some blobs like `libc.so`.
The source:
- for `x86_64` they are from Ubuntu 20.04 image;
- for `aarch64` they are from [developer.arm.com](https://developer.arm.com/-/media/Files/downloads/gnu-a/8.3-2019.03/binrel/gcc-arm-8.3-2019.03-x86_64-aarch64-linux-gnu.tar.xz?revision=2e88a73f-d233-4f96-b1f4-d8b36e9bb0b9&la=en)

- for `s390x` it is extracted from Docker image:
```
docker run -it s390x/ubuntu:18.04
apt update
apt install gcc

docker export b38a367a8a05 > s390x.tar
```

- for `powerpc64le` it is extracted from Docker image:

```
docker run -it ppc64le/ubuntu:14.04
apt update
apt install gcc

docker export b38a367a8a05 > ppc64.tar
```

The ubuntu version 14.04 is selected for better compatibility.

- for `x86_64-musl` they are from https://musl.cc/. Last updated from build 23-Nov-2021 04:50 (7e2fa1cbc6b6c23d15e7b65015777e89  x86_64-linux-musl-native.tgz).
- for `riscv` they are from Debian Unstable image
- for `loongarch64` they are from Debian Unstable image

FreeBSD:

```
https://clickhouse-datasets.s3.yandex.net/toolchains/toolchains/freebsd-11.3-toolchain.tar.xz
http://distcache.FreeBSD.org/local-distfiles/mikael/freebsd-12.2-aarch64-toolchain.tar.xz
```

TODO:
- build `compiler-rt` from sources and remove `libgcc.a` from here;
- simplify directory structure even more.
