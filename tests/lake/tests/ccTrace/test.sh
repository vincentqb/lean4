#!/usr/bin/env bash
source ../common.sh

./clean.sh

NO_BUILD_CODE=3

# Test that a custom C compiler (`LEAN_CC`, `CC`, or `cc` from `PATH`) is part of the trace of a
# module's C object: another compiler, or the same one run under another name (as `clang` and
# `clang++` are), rebuilds the object, while the same compiler found at another path does not.

if [ "$OS" = Windows_NT ]; then
  echo "skipped: the stand-in compilers are shell scripts"
  exit 0
fi
REAL_CC=$(command -v "${LEAN_CC:-cc}" || true)
if [ -z "$REAL_CC" ]; then
  echo "skipped: no C compiler found"
  exit 0
fi

# Two stand-in compilers that behave the same but are different files, a copy of the first at
# another path, and the first under another name
CCS="$PWD/.lake/compilers"
mkdir -p "$CCS/elsewhere"
for name in a b; do
  printf '#!/bin/sh\n# stand-in compiler %s\nexec "%s" "$@"\n' "$name" "$REAL_CC" > "$CCS/cc-$name"
  chmod +x "$CCS/cc-$name"
done
cp "$CCS/cc-a" "$CCS/elsewhere/cc-a"
ln -s cc-a "$CCS/cc-a-renamed"

LEAN_CC="$CCS/cc-a" test_run build +Hello:o
# the same compiler: up to date
LEAN_CC="$CCS/cc-a" test_run build +Hello:o --no-build
# the same compiler at another path: still up to date
LEAN_CC="$CCS/elsewhere/cc-a" test_run build +Hello:o --no-build
# the same compiler under another name: out of date
LEAN_CC="$CCS/cc-a-renamed" test_status $NO_BUILD_CODE build +Hello:o --no-build
# another compiler: out of date, and rebuilt
LEAN_CC="$CCS/cc-b" test_status $NO_BUILD_CODE build +Hello:o --no-build
LEAN_CC="$CCS/cc-b" test_out "Built Hello:c.o" build +Hello:o -v
LEAN_CC="$CCS/cc-b" test_run build +Hello:o --no-build

# Cleanup
rm -f produced.out
