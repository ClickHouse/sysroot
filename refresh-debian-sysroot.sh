#!/usr/bin/env bash
#
# Refresh a Debian-derived Linux sysroot (linux-riscv64, linux-loongarch64) from the
# current Debian packages. The packages are fetched with apt inside a throwaway
# Debian container (docker is required) and unpacked; only the pieces that
# ClickHouse's clang-based cross build needs are kept:
#
#   usr/include/                       glibc + kernel (uapi) headers
#   usr/lib/<triple>/                  crt1.o, Scrt1.o, crti.o, crtn.o, libc.so*, libm.so*,
#                                      the libpthread/librt/libdl stubs and ld.so
#   usr/lib/gcc/<triple>/<N>/          crtbegin*.o, crtend*.o, libgcc.a (found by clang
#                                      via --gcc-toolchain=<sysroot>/usr)
#   lib -> usr/lib                     merged-/usr layout, as on Debian itself
#
# Dropped on purpose: static glibc archives (ClickHouse links glibc dynamically),
# gconv/audit modules, GCC's own headers (clang ships its own), libgcc_eh/libgcov,
# and anything else the linker never opens.
#
# Usage:
#   ./refresh-debian-sysroot.sh riscv64        # from Debian stable (trixie)
#   ./refresh-debian-sysroot.sh loongarch64    # from Debian unstable (sid)
#
# The suite can be overridden: DEBIAN_SUITE=sid ./refresh-debian-sysroot.sh riscv64
# A different mirror: DEBIAN_MIRROR=http://deb.debian.org/debian

set -euo pipefail

ARCH="${1:-}"
case "$ARCH" in
  riscv64)
    DEB_ARCH=riscv64; TRIPLE=riscv64-linux-gnu; SUITE="${DEBIAN_SUITE:-trixie}"; SYSROOT=linux-riscv64 ;;
  loongarch64)
    # loong64 is not part of Debian 13 (trixie); it is an official architecture only from Debian 14 on.
    DEB_ARCH=loong64; TRIPLE=loongarch64-linux-gnu; SUITE="${DEBIAN_SUITE:-sid}"; SYSROOT=linux-loongarch64 ;;
  *)
    echo "Usage: $0 <riscv64|loongarch64>" >&2; exit 1 ;;
esac
MIRROR="${DEBIAN_MIRROR:-http://deb.debian.org/debian}"

cd "$(dirname "${BASH_SOURCE[0]}")"

STAGE="$(mktemp -d)"; trap 'rm -rf "$STAGE"' EXIT
mkdir -p "$STAGE/debs" "$STAGE/root"

echo "Fetching $DEB_ARCH packages from Debian $SUITE ..."
docker run --rm -v "$STAGE:/stage" "debian:${SUITE}-slim" bash -euo pipefail -c "
  cat > /etc/apt/sources.list.d/debian.sources <<SRC
Types: deb
URIs: $MIRROR
Suites: $SUITE
Components: main
SRC
  dpkg --add-architecture $DEB_ARCH
  apt-get -qq update
  # The default GCC of this suite decides which libgcc-<N>-dev provides crtbegin.o and libgcc.a.
  GCC_MAJOR=\$(apt-cache show gcc:$DEB_ARCH | sed -n 's/^Depends:.*[[:space:]]gcc-\([0-9][0-9]*\)[[:space:](,].*/\1/p' | head -n1)
  [ -n \"\$GCC_MAJOR\" ] || { echo 'cannot determine default gcc version' >&2; exit 1; }
  cd /stage/debs
  # linux-libc-dev is Architecture: all since Debian 13: one package carries the asm headers of every architecture.
  apt-get -qq download libc6:$DEB_ARCH libc6-dev:$DEB_ARCH linux-libc-dev libgcc-\$GCC_MAJOR-dev:$DEB_ARCH
  for deb in *.deb; do dpkg-deb -x \"\$deb\" /stage/root; done
  {
    echo \"Debian suite: $SUITE ($(date -u +%Y-%m-%d))\"
    for deb in *.deb; do dpkg-deb -f \"\$deb\" Package Version | paste -sd' '; done
  } > /stage/SOURCE.txt
  chown -R $(id -u):$(id -g) /stage
"
cat "$STAGE/SOURCE.txt"

ROOT="$STAGE/root"
GCC_DIR=$(ls -d "$ROOT/usr/lib/gcc/$TRIPLE"/*/)
GCC_DIR=${GCC_DIR%/}

rm -rf "${SYSROOT:?}"
mkdir -p "$SYSROOT/usr/lib/gcc/$TRIPLE" "$SYSROOT/usr/lib/$TRIPLE"

cp -a "$ROOT/usr/include" "$SYSROOT/usr/"
# linux-libc-dev (Architecture: all since Debian 13) ships usr/include/<triple>/asm for every
# Debian architecture as symlinks into usr/lib/linux/uapi/<kernel-arch>/asm. Keep only our
# triple and turn its asm/ into real files so that the sysroot is self-contained.
for d in "$SYSROOT"/usr/include/*-linux-gnu*; do [ "$(basename "$d")" = "$TRIPLE" ] || rm -rf "$d"; done
ASM_LINK=$(find "$ROOT/usr/include/$TRIPLE/asm" -maxdepth 1 -type l | head -n1)
[ -n "$ASM_LINK" ] || { echo "no symlinked asm/ headers found under usr/include/$TRIPLE" >&2; exit 1; }
UAPI_ASM_DIR=$(cd "$(dirname "$ASM_LINK")" && cd "$(dirname "$(readlink "$ASM_LINK")")" && pwd)
rm -rf "$SYSROOT/usr/include/$TRIPLE/asm"
cp -a "$UAPI_ASM_DIR" "$SYSROOT/usr/include/$TRIPLE/asm"
cp -a "$ROOT/usr/lib/$TRIPLE/." "$SYSROOT/usr/lib/$TRIPLE/"
# ld.so lives outside the multiarch dir on some architectures (/lib/ld-linux-*.so.*, /lib64/...).
cp -a "$ROOT"/usr/lib/ld-* "$SYSROOT/usr/lib/" 2>/dev/null || true
# Debian's libc.so linker script names ld.so by its absolute path (/lib64/ld-linux-*.so.1 or
# /lib/ld-linux-*.so.1); lld resolves it inside the sysroot, so the merged-/usr symlinks must exist.
if [ -d "$ROOT/usr/lib64" ]; then cp -a "$ROOT/usr/lib64" "$SYSROOT/usr/"; ln -s usr/lib64 "$SYSROOT/lib64"; fi
cp -a "$GCC_DIR" "$SYSROOT/usr/lib/gcc/$TRIPLE/"
ln -s usr/lib "$SYSROOT/lib"

# Prune what the linker never opens.
(
  cd "$SYSROOT/usr/lib/$TRIPLE"
  rm -rf gconv audit
  rm -f gcrt1.o grcrt1.o Mcrt1.o libnsl.so* libutil.so*
  rm -f -- *.py libc.a libm.a libm-*.a libmvec.a libmcheck.a libg.a libresolv.a libanl.a libBrokenLocale.a librpcsvc.a
  rm -f libc_malloc_debug.so* libmemusage.so libpcprofile.so libSegFault.so libthread_db.so* libnss_* libanl.so* libBrokenLocale.so* libmvec.so*
)
# From GCC keep only the startup objects and libgcc.a (the Rust host build links -lgcc).
find "$SYSROOT/usr/lib/gcc/$TRIPLE"/*/ -mindepth 1 -maxdepth 1 ! -name "crt*.o" ! -name libgcc.a -exec rm -rf {} +
cp "$STAGE/SOURCE.txt" "$SYSROOT/SOURCE.txt"

echo "glibc: $(grep -hE 'define[[:space:]]+__GLIBC_MINOR__' "$SYSROOT/usr/include/features.h")"
echo "kernel headers: $(grep -h 'define LINUX_VERSION_CODE' "$SYSROOT/usr/include/linux/version.h")"
echo "Sysroot refresh complete: $SYSROOT ($(du -sh "$SYSROOT" | cut -f1))"
