# Spot Python runtime wheels

This build packages the selected Spot release with Python bindings, shared
libraries and native command-line tools. It uses 64 acceptance sets. The
distribution is named `spot-runtime`, with version `SPOTVER+acc64`; imports
remain `spot` and `buddy`. It is separate from the static ITS-tools build.

The release defaults to the SPOTVER assignment in `../build_spot.sh`.
SPOT_VERSION and SPOT_SOURCE_URL can select a specific release/source archive.
The Python interpreter, OS and architecture determine the wheel compatibility
tags. The supported builders are Linux and macOS with CPython 3.10 or later.
The Windows static-tool workflow is independent; these wheels do not claim
Windows Python compatibility.

## Build and install

The builder needs a C++20 compiler, make, Python development headers, curl,
and the Python packages wheel and packaging. Linux relocation uses patchelf
0.19.1 or later (install it in the build Python environment);
macOS relocation uses the Xcode command-line tools. The release archive supplies
generated build files, so SWIG regeneration is not required.

```sh
PYTHON=python3 BUILD_JOBS=2 bash python/build.sh
python3 -m venv python/build/check-env
python/build/check-env/bin/python -m pip install --no-deps python/build/wheels/*.whl
python/build/check-env/bin/python -I python/smoke.py
```

For installation on other machines, Linux CI repairs the wheel with auditwheel
in a manylinux_2_28 container; macOS CI uses delocate. These tools bundle additional
non-system shared-library dependencies. Repaired wheels are written to dist/.
Local unrepaired wheels have the build host's compatibility requirements.

```sh
python3 -m pip install /path/to/spot_runtime-*.whl
python3 -c 'import spot, buddy; print(spot.version(), spot.mark_t.max_accsets())'
ltl2tgba -f GFa
```

Use a clean Python environment: another package providing spot or buddy would
overlap these modules. This runtime requires no checkout paths or loader
environment variables. Command entry points execute the bundled native tools.

## Packaging and checks

Build sources and installation prefixes live under build/. Packaging copies the
installed Python modules and native runtime into a temporary wheel tree. Native
libraries and tools reside inside spot_runtime/, and their loader paths are
relative to that package. The wheel contains the upstream license and release
source URL. No compilation occurs when installing a wheel.

The smoke scenario imports both bindings from the installed environment, checks
the release and acceptance-set limit, constructs and parses a small automaton,
and exercises the installed CLI and knowledge options. Each CLI invocation is
bounded. CI hides the build prefix before checking the repaired wheel, so the
test cannot succeed by loading libraries from that prefix.

The separate ../.github/workflows/python.yml workflow publishes wheel artifacts.
It does not write website/ or deploy to the legacy publishing branches.
Linux targets x86-64 with a manylinux_2_28 baseline. macOS has separate arm64
and x86-64 jobs. The interpreter matrix is declared in that workflow.

## Source map

- build.sh: release download, isolated native build and wheel assembly.
- package.py: installed-prefix assembly, relocation and wheel metadata.
- runtime.py: installed command entry point for bundled native executables.
- smoke.py: one installed-runtime end-to-end scenario.
