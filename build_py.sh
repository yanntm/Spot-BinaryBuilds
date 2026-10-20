#!/usr/bin/env bash
# Build Spot's upstream Python wheel and add a stable archive to website/.
# Needs Python 3.14, a C++20 compiler and make. CI uses two build jobs;
# locally: BUILD_JOBS=10 PYTHON=python3.14 ./build_py.sh
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
python_bin="${PYTHON:-python3}"
version="$(sed -n 's/^export SPOTVER=\([^ #]*\).*/\1/p' "$root/build_spot.sh")"
archive="$root/spot-$version.tar.gz"
work="$root/spot-python"
mkdir -p "$work" "$root/website"

if [[ ! -s "$archive" ]]; then
    curl --fail --location --retry 2 --connect-timeout 15 --max-time 120 \
        --output "$archive.part" "https://www.lre.epita.fr/dload/spot/spot-$version.tar.gz"
    mv "$archive.part" "$archive"
fi
"$python_bin" -m venv "$work/env"
python_bin="$work/env/bin/python"
export PATH="$work/env/bin:$PATH"
"$python_bin" -m pip install setuptools wheel 'patchelf>=0.19.1; sys_platform == "linux"'

# The static build modifies its source tree; use a fresh extraction here.
rm -rf "$work/source" "$work/wheels"
mkdir -p "$work/source" "$work/wheels"
tar -xzf "$archive" --strip-components=1 -C "$work/source"
export enable_max_accsets=64
export PYTHON_CPU_COUNT="${BUILD_JOBS:-2}"
"$python_bin" -m pip wheel --no-deps --no-build-isolation \
    --wheel-dir "$work/wheels" "$work/source"

case "$(uname -s)" in
    Linux) target=linux ;;
    Darwin) target=osx ;;
    *) echo 'Only Linux and macOS builds are supported' >&2; exit 1 ;;
esac
tar -czf "$root/website/spot_python_$target.tar.gz" -C "$work/wheels" .
