#!/usr/bin/env bash

set -euo pipefail

if [[ "$(uname -s)" != "SunOS" ]]; then
  cat <<EOF
Usage: ./refresh-illumos-sysroot.sh

Must be run on an illumos machine. OmniOS LTS is recommended.
EOF
  exit 1
fi

SYSROOT="./illumos-x86_64"
GCC_LIB_DIR=$(dirname "$(readlink -f /usr/lib/amd64/libgcc_s.so.1)")

echo "Sysroot: $SYSROOT"

rm -rf "${SYSROOT:?}"
mkdir -p "$SYSROOT"

gtar -C / -cf - \
    usr/include \
    lib/amd64 \
    usr/lib/amd64 \
    "${GCC_LIB_DIR#/}" \
  | gtar -xf - -C "$SYSROOT"

echo "Sysroot refresh complete: $SYSROOT"
