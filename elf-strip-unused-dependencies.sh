#!/bin/bash

binary=$1

# NOTE: only pick up the tab-indented absolute paths that make up the "Unused
# direct dependencies:" list. glibc's ldd also prints diagnostics such as
#   <binary>: Relink `' with `/usr/lib/libc.so.6' for IFUNC symbol `memcpy'
# to stdout; those are not indented, and matching them fed garbage to patchelf.
exec 3< <(ldd -u "$binary" | grep -oP '^\s+/\S*/\K[^/:]+$')

patchargs=""
dropped=""
while read -r dep; do
    dropped="$dep $dropped"
    patchargs="--remove-needed $dep $patchargs"
done <&3
exec 3<&-

if [[ $dropped == "" ]]; then
    exit 0
fi

echo -e "patchelf '$binary' - removing unused dependencies:\n $dropped"
patchelf $patchargs $binary
