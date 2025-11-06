#!/usr/bin/env bash

set -euo pipefail

URL="${1:-}"

if [[ -z "$URL" ]]; then
  cat <<EOF
Usage: ./refresh-freebsd-sysroot.sh <URL>

URL examples:
  https://download.freebsd.org/releases/arm64/13.4-RELEASE/base.txz
  https://download.freebsd.org/releases/amd64/13.4-RELEASE/base.txz
  https://download.freebsd.org/releases/powerpc64/13.4-RELEASE/base.txz

The sysroot directory is automatically determined from the URL architecture.
EOF
  exit 1
fi

if [[ "$URL" =~ /arm64/ ]]; then
  SYSROOT="./freebsd-aarch64"
elif [[ "$URL" =~ /amd64/ ]]; then
  SYSROOT="./freebsd-x86_64"
elif [[ "$URL" =~ /powerpc/ ]]; then
  SYSROOT="./freebsd-powerpc64le"
else
  echo "Error: Could not determine architecture from URL: $URL" >&2
  exit 1
fi

echo "Sysroot: $SYSROOT"

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
FREEBSD_BASE="$TMP/base.txz"

curl -SfL -o "$FREEBSD_BASE" "$URL"

tar xvf "$FREEBSD_BASE" -C "$TMP"
NEW_SYSROOT="$TMP"

rm -rf "${SYSROOT:?}/usr/include" "${SYSROOT:?}/usr/lib" "${SYSROOT:?}/lib"
mkdir -p "$SYSROOT/usr/include" "$SYSROOT/lib"
cp -va "$NEW_SYSROOT/usr/include/." "$SYSROOT/usr/include/"

for p in crt1.o crtbegin.o crtend.o crti.o crtn.o \
         libc.a libm.a librt.a; do
  cp -va "$NEW_SYSROOT/usr/lib/$p" "$SYSROOT/lib/"
done

cp -va "$NEW_SYSROOT/lib/libthr.so."* "$SYSROOT/lib/libpthread.so"
cp -va "$NEW_SYSROOT/lib/libc.so."* "$SYSROOT/lib/"
cp -va "$NEW_SYSROOT/lib/libm.so."* "$SYSROOT/lib/"
cp -va "$NEW_SYSROOT/usr/lib/librt.so."* "$SYSROOT/lib/"

libc_ver=$(ls "$SYSROOT/lib/libc.so."* | head -n1 | xargs -n1 basename)
libm_ver=$(ls "$SYSROOT/lib/libm.so."* | head -n1 | xargs -n1 basename)
librt_ver=$(ls "$SYSROOT/lib/librt.so."* | head -n1 | xargs -n1 basename)
ln -sfv "$libc_ver" "$SYSROOT/lib/libc.so"
ln -sfv "$libm_ver" "$SYSROOT/lib/libm.so"
ln -sfv "$librt_ver" "$SYSROOT/lib/librt.so"

ln -sf "../lib" "$SYSROOT/usr/lib"

echo "Sysroot refresh complete: $SYSROOT"
