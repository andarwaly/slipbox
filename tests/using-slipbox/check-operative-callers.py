#!/usr/bin/env python3
"""Reject forbidden /using-slipbox caller wording in operative Markdown."""
from pathlib import Path
import re
import sys

PATTERN = re.compile(r"Run `/using-slipbox`|through `/using-slipbox`")
QUOTE = (
    "Caller skills state the natural imperative action and append `/using-slipbox`.",
    "Write “Record the link `/using-slipbox`,” never “Run `/using-slipbox`” or",
    '“record the link through `/using-slipbox`.”',
)


def operative_lines(path: Path):
    lines = path.read_text(encoding="utf-8").splitlines()
    is_engine = path.as_posix().endswith("skills/using-slipbox/SKILL.md")
    excluded = set()
    for index, line in enumerate(lines):
        if is_engine and line.startswith("Caller skills state the natural imperative"):
            if tuple(lines[index:index + 3]) != QUOTE:
                raise ValueError(f"malformed required caller quotation in {path}:{index + 1}")
            excluded.update((index, index + 1, index + 2))
        if index in excluded:
            continue
        yield index + 1, line


def main(root: Path) -> int:
    violations = []
    for base in (root / "skills", root / "docs"):
        if not base.exists():
            continue
        for path in base.rglob("*.md"):
            if "docs/superpowers/plans/" in path.as_posix():
                continue
            try:
                for number, line in operative_lines(path):
                    if PATTERN.search(line):
                        violations.append(f"{path}:{number}:{line.strip()}")
            except ValueError as error:
                print(error, file=sys.stderr)
                return 2
    if violations:
        print("\n".join(violations), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("usage: check-operative-callers.py ROOT", file=sys.stderr)
        raise SystemExit(2)
    raise SystemExit(main(Path(sys.argv[1]).resolve()))
