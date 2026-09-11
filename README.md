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
- we don't need `libgcc_eh`, `libgcc_s`, sanitizer runtimes or any other GCC runtime: ClickHouse builds `compiler-rt` from sources and links with `-nodefaultlibs`;
- we definitely don't need Fortran headers;

The idea is to strip down the "toolchain" as much as possible and provide it as a submodule instead of tarball.
Actually it's not longer a "toolchain", it's just a collection of libc-related libraries and a few files for compiler builtins.

This gives us the following advantages:
- more easy to add new platforms (no need to search for complete toolchain, just copy the relevant files from the OS image);
- better understanding what's going on - only the relevant files included;
- avoid risks of supply-chain attacks;
- allow to use custom sysroot even for default (non-cross) build to get reproducible, hermetic builds;
- opens up for experiment of building the libc from sources;
- simplify using musl-libc instead of glibc (the musl build uses only the kernel headers from `linux-x86_64` / `linux-aarch64`; musl itself is built from sources in the main repository).

## What every sysroot must contain

Per target, exactly the files the clang driver and `lld` open when ClickHouse is linked with
`-nodefaultlibs -lc -lm -lrt -lpthread -ldl` (see `cmake/linux/default_libs.cmake` and
`cmake/freebsd/default_libs.cmake` in the main repository):

| Piece | Why |
|---|---|
| `usr/include` (libc + kernel/uapi headers) | compilation |
| `crt1.o`, `crti.o`, `crtn.o` (glibc / FreeBSD) and `Scrt1.o` where PIE is possible | program entry / `.init` / `.fini` |
| `crtbegin.o`, `crtend.o` (+ `S` variants) from GCC, or from FreeBSD base | static constructors / EH frame registration |
| `libgcc.a` | only linked by the Rust host build on x86_64 / aarch64 (`-lgcc`); kept on every target for uniformity, it is small |
| `libc.so*`, `libm.so*`, `librt.so*`, `libpthread.so*`, `libdl.so*`, `libc_nonshared.a`, `ld-*.so*` | link-time symbol resolution |

Anything else (static `libc.a`, `gconv`, GCC's own headers, `libgcc_eh`, `libgcc_s`, sanitizer
runtimes, OpenSSL, C++ headers of the target OS, DWARF sections inside the shared objects) is dead
weight and is intentionally not checked in. The shared objects are used by the linker only, so
`llvm-strip --strip-debug` is safe and is applied where the upstream ships unstripped files.

## The sysroots

| Directory | Source | glibc / libc | Kernel headers | GCC files | Notes |
|---|---|---|---|---|---|
| `linux-x86_64` | Ubuntu 20.04 blobs; headers from Ubuntu 18.04 (`usr/include`) | glibc 2.27 | 4.15 | gcc 9 | **Defines the minimum glibc of the official x86_64 binaries.** Do not upgrade casually. |
| `linux-aarch64` | Arm GNU Toolchain `gcc-arm-8.3-2019.03` (`aarch64-linux-gnu`) | glibc 2.28 | 4.19 | gcc 8.3 | **Defines the minimum glibc of the official aarch64 binaries.** Shared objects are stripped of debug info. |
| `linux-s390x` | Docker `s390x/ubuntu:18.04` + `apt install gcc` | glibc 2.27 | 4.15 | gcc 11 | |
| `linux-powerpc64le` | Docker `ppc64le/ubuntu:14.04` + `apt install gcc` | glibc 2.19 | 3.13 | gcc 4.8 | Deliberately old for compatibility with old ppc64le distributions. |
| `linux-riscv64` | Debian 13 (trixie) packages via `refresh-debian-sysroot.sh riscv64` | glibc 2.41 | 6.12 | gcc 14 | Debian merged-`/usr` layout, see `SOURCE.txt` inside. |
| `linux-loongarch64` | Debian unstable (sid) packages via `refresh-debian-sysroot.sh loongarch64` | glibc 2.43 | 7.1 | gcc 16 | loong64 is not in Debian 13; official only from Debian 14. See `SOURCE.txt` inside. |
| `freebsd-x86_64` | `FreeBSD 14.5-RELEASE` `base.txz` via `refresh-freebsd-sysroot.sh` | FreeBSD libc 7 | - | crt from base | Target triple `x86_64-pc-freebsd14` |
| `freebsd-aarch64` | same | | | | Target triple `aarch64-unknown-freebsd14` |
| `freebsd-powerpc64le` | same | | | | Target triple `powerpc64le-unknown-freebsd14` |

The linker records, for every glibc symbol, the newest symbol version present in the sysroot's
`libc.so`. The official x86_64 and aarch64 binaries must not reference symbol versions newer than
`GLIBC_2.4` / `GLIBC_2.18` (enforced by `ci/jobs/compatibility_check.py`); this is achieved by
`base/glibc-compatibility` in the main repository, which provides its own definitions of the
functions whose symbol versions are newer than that. A newer glibc in `linux-x86_64` /
`linux-aarch64` means more symbols to shim and a real risk of silently raising the glibc floor of
the release binaries, so these two are frozen. The other Linux sysroots have no such check.

## How to update

All updates happen in this repository on a branch, then the submodule pointer is bumped in
`ClickHouse/ClickHouse`. In every case, after updating, build ClickHouse for the affected
target (`cmake -DCMAKE_TOOLCHAIN_FILE=cmake/<os>/toolchain-<arch>.cmake ...`) and link
`programs/clickhouse` before opening the pull request; the CI jobs `amd_freebsd`, `ppc64le`,
`riscv64`, `s390x`, `loongarch64`, `amd_musl` cover the cross targets.

### FreeBSD (`freebsd-x86_64`, `freebsd-aarch64`, `freebsd-powerpc64le`)

```bash
# pick the release at https://download.freebsd.org/releases/ (old ones move to https://archive.freebsd.org/old-releases/)
./refresh-freebsd-sysroot.sh https://download.freebsd.org/releases/amd64/14.5-RELEASE/base.txz
./refresh-freebsd-sysroot.sh https://download.freebsd.org/releases/arm64/aarch64/14.5-RELEASE/base.txz
./refresh-freebsd-sysroot.sh https://download.freebsd.org/releases/powerpc/powerpc64le/14.5-RELEASE/base.txz
```

The script downloads `base.txz`, keeps `usr/include` (minus `c++` and `private`), the startup
objects and the shared `libc`, `libm`, `librt`, `libthr` (installed as `libpthread.so`), and
prints the resulting `__FreeBSD_version`.

If the *major* version changes, also change the target triple (`x86_64-pc-freebsdNN`,
`aarch64-unknown-freebsdNN`, `powerpc64le-unknown-freebsdNN`) in the main repository:
`cmake/freebsd/toolchain-*.cmake` and `ci/jobs/build_toolchain.py` (`CROSS_BUILTIN_TARGETS`).
The triple selects the libc symbol versions the binary is allowed to use, so a binary built with
sysroot N and triple N-1 is wrong. Binaries built against release N run on N and newer.

Stay on the oldest *supported* FreeBSD major (see https://www.freebsd.org/security/#sup): moving
to a newer major raises the minimum FreeBSD version users need.

### Debian-based Linux (`linux-riscv64`, `linux-loongarch64`)

Requires docker.

```bash
./refresh-debian-sysroot.sh riscv64        # Debian stable (trixie); override with DEBIAN_SUITE=...
./refresh-debian-sysroot.sh loongarch64    # Debian unstable (sid): loong64 is not in stable yet
```

The script runs a throwaway `debian:<suite>-slim` container, downloads `libc6`, `libc6-dev`,
`linux-libc-dev` and the `libgcc-<N>-dev` of the suite's default GCC for the target architecture,
unpacks them, keeps the pieces listed above and writes the exact package versions to
`<sysroot>/SOURCE.txt`. The resulting layout is Debian's merged-`/usr`:
`usr/include`, `usr/lib/<triple>`, `usr/lib/gcc/<triple>/<N>`, `lib -> usr/lib`.

The toolchain files pass `--sysroot=<sysroot>` and `--gcc-toolchain=<sysroot>/usr`; clang
discovers the GCC version directory itself, so a new GCC major needs no cmake change.

To move a target from sid to stable once the architecture is released there, change the default
`SUITE` in the script (or run with `DEBIAN_SUITE=`).

### Ubuntu-based Linux (`linux-x86_64`, `linux-s390x`, `linux-powerpc64le`)

There is no script because these are frozen on purpose (glibc floor). If a refresh is ever
needed, the procedure that produced them is:

```bash
docker run -it --platform linux/<amd64|s390x|ppc64le> ubuntu:<version>
apt update && apt install gcc
docker export <container-id> > rootfs.tar
```

Then copy from the tarball, keeping the existing directory layout of the sysroot
(`<triple>/libc/{lib,lib64,usr/include,usr/lib64}` and `lib/gcc/<triple>/<N>/`):

- `usr/include/**` -> `<triple>/libc/usr/include/`
- `lib/<triple>/{libc.so.6,libm.so.6,libpthread.so.0,librt.so.1,libdl.so.2,libresolv.so.2}` -> `<triple>/libc/lib64/`
- `lib/<triple>/ld-*.so*` -> `<triple>/libc/lib/`
- `usr/lib/<triple>/{crt1.o,Scrt1.o,crti.o,crtn.o,libc.so,libc_nonshared.a}` -> `<triple>/libc/usr/lib64/`
- `usr/lib/gcc/<triple>/<N>/{crtbegin.o,crtbeginS.o,crtbeginT.o,crtend.o,crtendS.o,libgcc.a}` -> `lib/gcc/<triple>/<N>/`

To only add kernel headers (the usual reason to touch `linux-x86_64`, e.g. a new `linux/*.h`),
take them from the `linux-libc-dev` package of the *same* Ubuntu release and put them under
`x86_64-linux-gnu/libc/usr/include/linux/`; do not mix a newer glibc's `bits/` headers with the old
`libc.so`.

### `linux-aarch64`

Taken from the Arm GNU Toolchain release
https://developer.arm.com/downloads/-/gnu-a/8-3-2019-03 (`gcc-arm-8.3-2019.03-x86_64-aarch64-linux-gnu.tar.xz`).
Newer Arm GNU Toolchain releases ship newer glibc (15.2.Rel1 = glibc 2.42) and would raise the
glibc floor of the official aarch64 binaries, so the same caution as for `linux-x86_64` applies.
The layout is the toolchain's own: `aarch64-linux-gnu/libc/{lib,lib64,usr/include,usr/lib64}` and
`lib/gcc/aarch64-linux-gnu/<N>/`. After copying, run
`llvm-strip --strip-debug` on the shared objects (the toolchain ships them with DWARF).

### Adding a new Linux target

1. Get a rootfs with glibc + gcc for the target (Debian packages via `refresh-debian-sysroot.sh`
   with a new `case` entry are the easiest).
2. Add `cmake/linux/toolchain-<arch>.cmake` in the main repository, modelled on
   `toolchain-loongarch64.cmake` (`CMAKE_SYSROOT` = sysroot root, `--gcc-toolchain` = the
   directory containing `lib/gcc/<triple>/<N>`).
3. Add compiler-rt builtins sources for the architecture in `contrib/compiler-rt-cmake` and the
   triple to `CROSS_BUILTIN_TARGETS` in `ci/jobs/build_toolchain.py`.

## musl

The musl build (`cmake/linux/toolchain-x86_64-musl.cmake`, `toolchain-aarch64-musl.cmake`) uses
no musl sysroot: musl is built from sources (`contrib/musl`, `contrib/musl-cmake`), and the only
thing taken from this repository is the kernel uapi headers of `linux-x86_64` / `linux-aarch64`
(`cmake/musl.cmake` symlinks `linux/`, `asm/`, `asm-generic/`, ... into the build directory).
