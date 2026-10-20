# Spot-BinaryBuilds
Provides up to date Spot artifacts for [ITS-tools](https://github.com/lip6/ITSTools) builds

Builds using GitHub actions and [custom releases](https://spot.lrde.epita.fr/install.html) from the main source repo of [Spot](https://spot.lrde.epita.fr/) at LRDE.

Build is currently aligned with the Spot 2.16 release (2026-09-03), which carries the knowledge integration (`--given-*`, `auto-small`, `auto-si`) we used a dev snapshot for; `tools/` holds spotutil, our own static tool over the Spot API (see `tools/README.md`).

The independent [Python runtime build](python/README.md) produces installable
spot-runtime wheels with Python bindings and bundled native dependencies.
Its workflow publishes separate job artifacts; static builds and their
published files keep their own build and deployment paths.


