"""Check one installed runtime through its Python bindings and CLI tools."""
from __future__ import annotations

from importlib.metadata import version
from pathlib import Path
import subprocess
import sys

import buddy
import spot


def main() -> None:
    """Check installation isolation, ABI-sensitive imports and native behavior."""
    prefix = Path(sys.prefix).resolve()
    for module in (spot, buddy):
        assert Path(module.__file__).resolve().is_relative_to(prefix), module.__file__
    assert spot.mark_t.max_accsets() == 64
    marks = spot.mark_t([63])
    assert tuple(marks.sets()) == (63,)
    assert (buddy.bddtrue & buddy.bddtrue) == buddy.bddtrue
    automaton = spot.translate("GFa", "BA")
    assert not automaton.is_empty()
    bindir = Path(sys.executable).parent
    translated = subprocess.run([str(bindir / "ltl2tgba"), "-f", "GFa"],
                                check=True, capture_output=True, text=True, timeout=5)
    assert not spot.automaton(translated.stdout).is_empty()
    simplified = subprocess.run(
        [str(bindir / "autfilt"), "--given-formula", "1", "--given-strategy", "auto-small"],
        input=translated.stdout, check=True, capture_output=True, text=True, timeout=5)
    assert not spot.automaton(simplified.stdout).is_empty()
    subprocess.run([str(bindir / "ltlfilt"), "-f", "GFa"],
                   check=True, capture_output=True, timeout=5)
    release = version("spot-runtime")
    assert spot.version() == release.split("+")[0], (spot.version(), release)
    print(f"PASS {release}: installed bindings, mark 63, CLI and knowledge options")


if __name__ == "__main__":
    main()
