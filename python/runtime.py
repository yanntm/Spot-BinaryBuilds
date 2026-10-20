"""Command entry point for the bundled Spot executables."""
from __future__ import annotations

import os
from pathlib import Path
import sys


def main() -> None:
    """Execute the native command selected by its installed entry-point name."""
    name = Path(sys.argv[0]).name
    executable = Path(__file__).parent / "bin" / name
    if not executable.is_file():
        raise SystemExit(f"No bundled Spot command named {name}")
    os.execv(str(executable), [str(executable), *sys.argv[1:]])
