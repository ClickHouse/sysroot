#!/usr/bin/env bash
#
# Add the bits to each Linux cross-sysroot that are needed to link
# ClickHouse as a Position-Independent Executable (PIE).
#
# Design philosophy: do the smallest possible change per target. For each
# arch we only add what is missing:
#
#   * riscv64
#       - The sysroot already ships `librt.so.1` (glibc 2.32) and a
#         non-PIC `librt.a`. There is no `librt.so` symlink, so `-lrt`
#         falls back to the static archive and the linker emits
#         R_RISCV_HI20/LO12 errors against a PIE output.
#       - Fix: add a `librt.so -> librt.so.1` symlink. (usr/lib is a
#         symlink to ../lib in this sysroot, so we only touch one path.)
#         That makes `-lrt` resolve to the shared library, which contains
#         all the POSIX-timer symbols we need.
#       - No new files are downloaded. No archives are replaced. The
#         runtime glibc floor for the resulting binary is unchanged.
#
#   * ppc64le
#       - The sysroot has no PIE entry object. Linking with `-pie` fails
#         with "cannot open Scrt1.o".
#       - Fix: copy `Scrt1.o` from Debian trixie's libc6-dev-ppc64el-cross
#         package into both lib64 paths the sysroot uses. `Scrt1.o` only
#         references `__libc_start_main` (present since glibc 2.0), so it
#         is safe to drop into an older sysroot.
#
#   * loongarch64
#       - Same story as ppc64le: no `Scrt1.o`.
#       - Fix: copy `Scrt1.o` from Debian trixie's libc6-dev-loong64-cross
#         package into `usr/lib/loongarch64-linux-gnu/`.
#
#   * x86_64-musl
#       - ClickHouse's musl build is statically linked (`-static -lc`). Under
#         `-pie`, that combination is incoherent: clang's driver picks
#         `crtbeginT.o` (the non-PIC "typical" static-exe CRT) and `lld`
#         then rejects its absolute `R_X86_64_32` relocations against
#         `__TMC_END__` etc. Switching to `-static-pie` makes the driver
#         pick the PIC variants (`rcrt1.o`, `crtbeginS.o`, `crtendS.o`),
#         but those files are not in this sysroot.
#       - Fix: copy `rcrt1.o` (musl's relocatable CRT entry), `crtbeginS.o`
#         and `crtendS.o` from Alpine's musl-dev / libgcc / gcc packages
#         into `lib/`. musl's existing `libc.a` / `crt1.o` / `crti.o` /
#         `crtn.o` are already PIC-clean, so no other changes are needed.
#         The corresponding build-system change is to switch the musl
#         build from `-static` to `-static-pie` in
#         `cmake/linux/default_libs.cmake` in the main repo.
#
# This script is intentionally not a "full sysroot refresh". Upgrading
# the glibc/musl version compiled against is a separate, larger change.
#
# Usage:
#   ./refresh-linux-sysroot.sh <arch>      # refresh one arch
#   ./refresh-linux-sysroot.sh all         # refresh all four
#
# Supported <arch>: riscv64, ppc64le, loongarch64, x86_64-musl
#
# Requires: docker (for all arches except riscv64).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

STAGE_ROOT=""
cleanup() {
  if [[ -n "$STAGE_ROOT" && -d "$STAGE_ROOT" ]]; then
    rm -rf "$STAGE_ROOT"
  fi
}
trap cleanup EXIT

# Extract libc6-dev-<arch>-cross from Debian trixie into a staging dir.
# We run the container as root (apt-get needs it) and chown the output tree
# back to the invoking user so the host can clean it up without sudo.
#
# Result is placed in the global variable EXTRACTED_DIR. We avoid command
# substitution here because `FOO=$(func)` runs `func` in a subshell, so any
# modifications to globals (including STAGE_ROOT) and any EXIT traps are
# lost as soon as the subshell finishes.
EXTRACTED_DIR=""
extract_cross_dev() {
  local deb_arch="$1"
  if [[ -z "$STAGE_ROOT" ]]; then
    STAGE_ROOT="$(mktemp -d)"
  fi
  local dest="$STAGE_ROOT/$deb_arch"
  if [[ -d "$dest/usr" ]]; then
    EXTRACTED_DIR="$dest"
    return 0
  fi
  mkdir -p "$dest"
  local uid gid
  uid="$(id -u)"
  gid="$(id -g)"
  docker run --rm -v "$dest":/out debian:trixie-slim bash -c "
    set -e
    apt-get update -qq >/dev/null
    mkdir -p /tmp/debs && cd /tmp/debs
    apt-get download libc6-dev-${deb_arch}-cross >/dev/null
    for d in *.deb; do dpkg-deb -x \"\$d\" /out; done
    chown -R ${uid}:${gid} /out
  " >/dev/null
  EXTRACTED_DIR="$dest"
}

refresh_riscv64() {
  local sysroot="$SCRIPT_DIR/linux-riscv64"
  local dir="$sysroot/lib/riscv64-linux-gnu"
  echo ">> riscv64: $sysroot"
  if [[ ! -d "$dir" ]]; then
    echo "Error: missing target dir $dir" >&2
    return 1
  fi
  # Note: usr/lib is a symlink to ../lib in this sysroot so this also
  # makes the file visible under usr/lib/riscv64-linux-gnu/librt.so.
  if [[ -L "$dir/librt.so" ]]; then
    echo "   $dir/librt.so already a symlink, leaving it"
  else
    ln -sfv librt.so.1 "$dir/librt.so"
  fi
}

refresh_ppc64le() {
  local sysroot="$SCRIPT_DIR/linux-powerpc64le"
  local triplet="powerpc64le-linux-gnu"
  echo ">> ppc64le: $sysroot"

  extract_cross_dev ppc64el
  local src="$EXTRACTED_DIR/usr/${triplet}/lib/Scrt1.o"
  if [[ ! -e "$src" ]]; then
    echo "Error: Scrt1.o not found in libc6-dev-ppc64el-cross at $src" >&2
    return 1
  fi

  for rel in ${triplet}/libc/lib64 ${triplet}/libc/usr/lib64; do
    local dir="$sysroot/$rel"
    if [[ ! -d "$dir" ]]; then
      echo "   Skipping missing dir: $dir" >&2
      continue
    fi
    cp --preserve=mode,timestamps -v "$src" "$dir/Scrt1.o"
  done
}

refresh_loongarch64() {
  local sysroot="$SCRIPT_DIR/linux-loongarch64"
  local triplet="loongarch64-linux-gnu"
  echo ">> loongarch64: $sysroot"

  # Debian calls this arch "loong64", but the GNU triplet is
  # "loongarch64-linux-gnu" and that is what the sysroot uses.
  extract_cross_dev loong64
  local src="$EXTRACTED_DIR/usr/${triplet}/lib/Scrt1.o"
  if [[ ! -e "$src" ]]; then
    echo "Error: Scrt1.o not found in libc6-dev-loong64-cross at $src" >&2
    return 1
  fi

  local dir="$sysroot/usr/lib/${triplet}"
  if [[ ! -d "$dir" ]]; then
    echo "Error: missing target dir $dir" >&2
    return 1
  fi
  cp --preserve=mode,timestamps -v "$src" "$dir/Scrt1.o"
}

# Pull the PIC CRT startup objects for x86_64-linux-musl out of Alpine's
# `musl-dev` + `libgcc` packages. Unlike the Debian-based arches above we
# can't use `apt-get download` here because Debian does not ship a
# musl-dev-x86-64-cross package; Alpine is the canonical source.
extract_alpine_musl() {
  if [[ -z "$STAGE_ROOT" ]]; then
    STAGE_ROOT="$(mktemp -d)"
  fi
  local dest="$STAGE_ROOT/alpine-musl"
  if [[ -d "$dest/usr" ]]; then
    EXTRACTED_DIR="$dest"
    return 0
  fi
  mkdir -p "$dest"
  local uid gid
  uid="$(id -u)"
  gid="$(id -g)"
  # musl-dev ships rcrt1.o / crt1.o / crti.o / crtn.o / libc.a.
  # The PIC crtstuff (crtbeginS.o, crtendS.o) lives in the `gcc` package,
  # not `libgcc` — libgcc only has the shared runtime.
  docker run --rm -v "$dest":/out alpine:latest sh -c "
    set -e
    cd /out
    apk fetch --no-cache --quiet musl-dev gcc 2>/dev/null
    for f in *.apk; do tar -xzf \"\$f\" 2>/dev/null || true; done
    chown -R ${uid}:${gid} /out
  " >/dev/null
  EXTRACTED_DIR="$dest"
}

refresh_x86_64_musl() {
  local sysroot="$SCRIPT_DIR/linux-x86_64-musl"
  echo ">> x86_64-musl: $sysroot"

  extract_alpine_musl
  local dir="$sysroot/lib"
  if [[ ! -d "$dir" ]]; then
    echo "Error: missing target dir $dir" >&2
    return 1
  fi

  # musl's relocatable CRT entry object (driver picks this for -static-pie).
  local rcrt1="$EXTRACTED_DIR/usr/lib/rcrt1.o"
  if [[ ! -e "$rcrt1" ]]; then
    echo "Error: rcrt1.o not found in Alpine musl-dev at $rcrt1" >&2
    return 1
  fi
  cp --preserve=mode,timestamps -v "$rcrt1" "$dir/rcrt1.o"

  # PIC variants of libgcc's crtstuff. They live under a versioned
  # gcc-toolchain directory inside the libgcc package; glob for the first
  # one we find so we don't hard-code the gcc version.
  local gcclib
  gcclib=$(ls -d "$EXTRACTED_DIR"/usr/lib/gcc/x86_64-alpine-linux-musl/*/ 2>/dev/null | head -1 || true)
  if [[ -z "$gcclib" ]]; then
    echo "Error: no libgcc tree under $EXTRACTED_DIR/usr/lib/gcc/" >&2
    return 1
  fi
  for f in crtbeginS.o crtendS.o; do
    if [[ ! -e "$gcclib/$f" ]]; then
      echo "Error: $f not found under $gcclib" >&2
      return 1
    fi
    cp --preserve=mode,timestamps -v "$gcclib/$f" "$dir/$f"
  done
}

ARCH="${1:-}"
if [[ -z "$ARCH" ]]; then
  cat <<EOF
Usage: $0 <arch>

Supported <arch>: riscv64, ppc64le, loongarch64, x86_64-musl, all
EOF
  exit 1
fi

case "$ARCH" in
  riscv64)     refresh_riscv64 ;;
  ppc64le)     refresh_ppc64le ;;
  loongarch64) refresh_loongarch64 ;;
  x86_64-musl) refresh_x86_64_musl ;;
  all)
    refresh_riscv64
    refresh_ppc64le
    refresh_loongarch64
    refresh_x86_64_musl
    ;;
  *)
    echo "Error: unsupported arch '$ARCH'." >&2
    exit 1
    ;;
esac

echo
echo "Done. Review with: git -C ${SCRIPT_DIR} status"
