#!/usr/bin/env bash
# Build a separate shared Spot runtime; see README.md.
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
python_bin="${PYTHON:-python3}"
version="${SPOT_VERSION:-$(sed -n 's/^export SPOTVER=\([^ #]*\).*/\1/p' "$root/build_spot.sh")}"
source_url="${SPOT_SOURCE_URL:-https://www.lre.epita.fr/dload/spot/spot-$version.tar.gz}"
jobs="${BUILD_JOBS:-2}"
[[ $# == 0 && -n "$version" ]] || { echo "usage: bash python/build.sh" >&2; exit 2; }

python_bin="$("$python_bin" -c 'import sys; print(sys.executable)')"
export PATH="$(dirname "$python_bin"):$PATH"
abi="$("$python_bin" -c 'import sys; print("cp%d%d" % sys.version_info[:2])')"
work="$root/python/build/$version/$abi"
archive="$root/python/build/spot-$version.tar.gz"
source_dir="$root/python/build/spot-$version"
prefix="$work/install"
mkdir -p "$work/native" "$root/python/build/wheels"

if [[ ! -s "$archive" ]]; then
    curl --fail --location --retry 2 --connect-timeout 15 --max-time 120 \
        --output "$archive.part" "$source_url"
    mv "$archive.part" "$archive"
fi
if [[ ! -f "$source_dir/configure" ]]; then
    tar -xzf "$archive" -C "$root/python/build"
fi

cd "$work/native"
"$source_dir/configure" PYTHON="$python_bin" VALGRIND=false \
    --prefix="$prefix" --libdir="$prefix/lib" \
    --disable-devel --without-included-lbtt --disable-static \
    --enable-shared --enable-python --enable-max-accsets=64
make -j"$jobs"
make install

"$python_bin" "$root/python/package.py" --prefix "$prefix" \
    --source "$source_dir" --version "$version" \
    --output "$root/python/build/wheels"
