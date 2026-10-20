"""Assemble a relocatable native runtime wheel; see README.md."""
from __future__ import annotations

import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys
import sysconfig
import tempfile
from typing import List

from packaging.tags import Tag, sys_tags
from packaging.version import Version
from wheel.wheelfile import WheelFile


def is_native(path: Path) -> bool:
    """Whether a file is an ELF or Mach-O binary."""
    with path.open("rb") as stream:
        return stream.read(4) in {
            b"\x7fELF", b"\xcf\xfa\xed\xfe", b"\xfe\xed\xfa\xcf",
            b"\xce\xfa\xed\xfe", b"\xfe\xed\xfa\xce", b"\xca\xfe\xba\xbe",
            b"\xbe\xba\xfe\xca", b"\xca\xfe\xba\xbf", b"\xbf\xba\xfe\xca",
        }


def copy_runtime(prefix: Path, tree: Path) -> List[str]:
    """Copy Python modules, shared libraries and native tools into wheel layout."""
    sites = sorted({site.resolve() for site in prefix.glob("lib*/python*/site-packages")})
    if sum((site / "spot" / "__init__.py").is_file() for site in sites) != 1:
        raise ValueError(f"Expected one installed spot package under {prefix}")
    ignored = shutil.ignore_patterns("__pycache__", "*.pyc", "*.la", "*.a")
    for site in sites:
        shutil.copytree(site, tree, dirs_exist_ok=True, ignore=ignored)
    runtime = tree / "spot_runtime"
    libraries, binaries = runtime / "lib", runtime / "bin"
    libraries.mkdir(parents=True)
    binaries.mkdir()
    shutil.copy2(Path(__file__).with_name("runtime.py"), runtime / "__init__.py")
    for path in sorted((prefix / "lib").iterdir()):
        if path.is_file() and (".so" in path.name or path.suffix == ".dylib"):
            shutil.copy2(path, libraries / path.name)
    commands = []
    for path in sorted((prefix / "bin").iterdir()):
        if path.is_file() and os.access(path, os.X_OK) and is_native(path):
            shutil.copy2(path, binaries / path.name)
            commands.append(path.name)
    if not commands or not any(libraries.iterdir()):
        raise ValueError("The installed prefix has no native tools or shared libraries")
    return commands


def relocate(tree: Path, prefix: Path) -> None:
    """Give bundled binaries loader paths relative to the wheel's library folder."""
    if sys.platform.startswith("linux"):
        tool_version = subprocess.check_output(["patchelf", "--version"], text=True).split()[-1]
        if Version(tool_version) < Version("0.19.1"):
            raise ValueError("Linux wheel relocation requires patchelf >= 0.19.1")
    libraries = tree / "spot_runtime" / "lib"
    names = {path.name for path in libraries.iterdir()}
    for path in sorted(tree.rglob("*")):
        if not path.is_file() or not is_native(path):
            continue
        relative = os.path.relpath(libraries, path.parent)
        if sys.platform.startswith("linux"):
            subprocess.run(["strip", "--strip-unneeded", str(path)], check=True)
            rpath = "$ORIGIN" if relative == "." else f"$ORIGIN/{relative}"
            subprocess.run(["patchelf", "--set-rpath", rpath, str(path)], check=True)
        elif sys.platform == "darwin":
            subprocess.run(["strip", "-S", str(path)], check=True)
            output = subprocess.check_output(["otool", "-L", str(path)], text=True)
            for line in output.splitlines()[1:]:
                dependency = line.strip().split()[0]
                name = Path(dependency).name
                if name in names:
                    target = f"@loader_path/{relative}/{name}"
                    subprocess.run(["install_name_tool", "-change", dependency,
                                    target, str(path)], check=True)
                elif dependency.startswith(str(prefix)):
                    raise ValueError(f"Unbundled build dependency: {dependency}")
            if path.suffix == ".dylib":
                subprocess.run(["install_name_tool", "-id", f"@rpath/{path.name}",
                                str(path)], check=True)
            subprocess.run(["codesign", "--force", "--sign", "-", "--timestamp=none",
                            str(path)], check=True)
        else:
            raise ValueError(f"Unsupported native platform: {sys.platform}")


def build_wheel(prefix: Path, source: Path, release: str, output: Path) -> Path:
    """Create one interpreter/platform-specific wheel from an installed prefix."""
    version = str(Version(release + "+acc64"))
    first = next(sys_tags())
    platform = (sysconfig.get_platform().replace("-", "_").replace(".", "_")
                if sys.platform.startswith("linux") else first.platform)
    tag = Tag(first.interpreter, first.abi, platform)
    output.mkdir(parents=True, exist_ok=True)
    wheel = output / f"spot_runtime-{version}-{tag}.whl"
    with tempfile.TemporaryDirectory(prefix="wheel-", dir=output.parent) as temporary:
        tree = Path(temporary)
        commands = copy_runtime(prefix, tree)
        relocate(tree, prefix)
        metadata = tree / f"spot_runtime-{version}.dist-info"
        metadata.mkdir()
        (metadata / "licenses").mkdir()
        shutil.copy2(source / "COPYING", metadata / "licenses" / "COPYING")
        (metadata / "METADATA").write_text(
            "Metadata-Version: 2.4\nName: spot-runtime\n"
            f"Version: {version}\nSummary: Spot Python and CLI runtime with 64 acceptance sets\n"
            "Requires-Python: >=3.10\nLicense-Expression: GPL-3.0-or-later\n"
            "License-File: licenses/COPYING\n"
            "Project-URL: Homepage, https://spot.lre.epita.fr\n"
            f"Project-URL: Source, https://www.lre.epita.fr/dload/spot/spot-{release}.tar.gz\n",
            encoding="utf-8")
        (metadata / "WHEEL").write_text(
            "Wheel-Version: 1.0\nGenerator: Spot-BinaryBuilds\n"
            f"Root-Is-Purelib: false\nTag: {tag}\n", encoding="utf-8")
        (metadata / "entry_points.txt").write_text(
            "[console_scripts]\n" + "".join(f"{name} = spot_runtime:main\n" for name in commands),
            encoding="utf-8")
        with WheelFile(wheel, "w") as archive:
            archive.write_files(str(tree))
    return wheel


def main() -> None:
    """Assemble the installed prefix selected by command-line arguments."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--prefix", type=Path, required=True)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    print(build_wheel(args.prefix.resolve(), args.source.resolve(), args.version,
                      args.output.resolve()))


if __name__ == "__main__":
    main()
