#!/usr/bin/env bash
#
# Refresh one FreeBSD sysroot (freebsd-x86_64, freebsd-aarch64, freebsd-powerpc64le)
# from an official base.txz. Only the pieces ClickHouse needs are kept:
#
#   * usr/include        - libc / kernel headers. The C++ headers (usr/include/c++)
#                          are dropped because ClickHouse builds its own libc++, and
#                          the base-system private headers (usr/include/private) are
#                          dropped because nothing may include them.
#   * lib/               - startup objects (crt1.o, Scrt1.o, crti.o, crtn.o,
#                          crtbegin*.o, crtend*.o) and the shared libraries that
#                          cmake/freebsd/default_libs.cmake links (-lc -lm -lrt
#                          -lpthread). Static archives (libc.a, ...) are not needed:
#                          ClickHouse links FreeBSD binaries dynamically.
#   * usr/lib -> ../lib  - clang looks for both.
#
# After refreshing, if the major version changed, also change the target triple in
# cmake/freebsd/toolchain-*.cmake and ci/jobs/build_toolchain.py of the main repo
# (e.g. x86_64-pc-freebsd14), since the triple selects the libc ABI level.

set -euo pipefail

URL="${1:-}"

if [[ -z "$URL" ]]; then
  cat <<USAGE
Usage: ./refresh-freebsd-sysroot.sh <URL>

URL examples (see https://download.freebsd.org/releases/ for current versions;
old releases move to https://archive.freebsd.org/old-releases/):
  https://download.freebsd.org/releases/amd64/14.5-RELEASE/base.txz
  https://download.freebsd.org/releases/arm64/aarch64/14.5-RELEASE/base.txz
  https://download.freebsd.org/releases/powerpc/powerpc64le/14.5-RELEASE/base.txz

The sysroot directory is determined from the architecture in the URL.
USAGE
  exit 1
fi

cd "$(dirname "${BASH_SOURCE[0]}")"

if [[ "$URL" =~ /arm64/ ]]; then
  SYSROOT="./freebsd-aarch64"
elif [[ "$URL" =~ /amd64/ ]]; then
  SYSROOT="./freebsd-x86_64"
elif [[ "$URL" =~ /powerpc64le/ ]]; then
  SYSROOT="./freebsd-powerpc64le"
else
  echo "Error: Could not determine architecture from URL: $URL" >&2
  exit 1
fi

echo "Sysroot: $SYSROOT"

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
FREEBSD_BASE="$TMP/base.txz"

curl -sSfL -o "$FREEBSD_BASE" "$URL"

# Extract only what is needed; base.txz is ~150 MB compressed, ~1 GB unpacked.
tar xf "$FREEBSD_BASE" --warning=no-unknown-keyword -C "$TMP" ./usr/include ./usr/lib ./lib
NEW_SYSROOT="$TMP"

rm -rf "${SYSROOT:?}/usr/include" "${SYSROOT:?}/usr/lib" "${SYSROOT:?}/lib"
mkdir -p "$SYSROOT/usr/include" "$SYSROOT/lib"
cp -a "$NEW_SYSROOT/usr/include/." "$SYSROOT/usr/include/"
rm -rf "$SYSROOT/usr/include/c++" "$SYSROOT/usr/include/private"

for p in crt1.o Scrt1.o crti.o crtn.o crtbegin.o crtbeginS.o crtend.o crtendS.o; do
  cp -v "$NEW_SYSROOT/usr/lib/$p" "$SYSROOT/lib/"
done

# libpthread is libthr on FreeBSD; -lpthread must resolve to the real shared object.
cp -v "$NEW_SYSROOT"/lib/libthr.so.* "$SYSROOT/lib/libpthread.so"
cp -v "$NEW_SYSROOT"/lib/libc.so.* "$SYSROOT/lib/"
cp -v "$NEW_SYSROOT"/lib/libm.so.* "$SYSROOT/lib/"
# librt moved from /usr/lib to /lib in FreeBSD 14.
cp -v "$NEW_SYSROOT"/lib/librt.so.* "$SYSROOT/lib/" 2>/dev/null || cp -v "$NEW_SYSROOT"/usr/lib/librt.so.* "$SYSROOT/lib/"

libc_ver=$(ls "$SYSROOT"/lib/libc.so.* | head -n1 | xargs -n1 basename)
libm_ver=$(ls "$SYSROOT"/lib/libm.so.* | head -n1 | xargs -n1 basename)
librt_ver=$(ls "$SYSROOT"/lib/librt.so.* | head -n1 | xargs -n1 basename)
ln -sfv "$libc_ver" "$SYSROOT/lib/libc.so"
ln -sfv "$libm_ver" "$SYSROOT/lib/libm.so"
ln -sfv "$librt_ver" "$SYSROOT/lib/librt.so"

ln -sfn "../lib" "$SYSROOT/usr/lib"

echo "FreeBSD version: $(grep -h 'define __FreeBSD_version' "$SYSROOT/usr/include/sys/param.h")"
echo "Sysroot refresh complete: $SYSROOT ($(du -sh "$SYSROOT" | cut -f1))"
