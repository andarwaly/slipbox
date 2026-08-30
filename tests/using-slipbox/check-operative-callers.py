#!/usr/bin/env python3
"""Reject forbidden /using-slipbox caller wording in operative Markdown."""
from pathlib import Path
import re
import sys

PATTERN = re.compile(r"Run `/using-slipbox`|through `/using-slipbox`")


def operative_lines(path: Path):
    lines = path.read_text(encoding="utf-8").splitlines()
    in_required_quote = False
    for number, line in enumerate(lines, 1):
        if path.as_posix().endswith("skills/using-slipbox/SKILL.md") and line.startswith("Caller skills state the natural imperative"):
            in_required_quote = True
        if in_required_quote:
            if line.startswith("“record the link through `/using-slipbox`"):
                in_required_quote = False
            continue
        yield number, line


def main(root: Path) -> int:
    violations = []
    for base in (root / "skills", root / "docs"):
        if not base.exists():
            continue
        for path in base.rglob("*.md"):
            if "docs/superpowers/plans/" in path.as_posix():
                continue
            for number, line in operative_lines(path):
                if PATTERN.search(line):
                    violations.append(f"{path}:{number}:{line.strip()}")
    if violations:
        print("\n".join(violations), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("usage: check-operative-callers.py ROOT", file=sys.stderr)
        raise SystemExit(2)
    raise SystemExit(main(Path(sys.argv[1]).resolve()))
