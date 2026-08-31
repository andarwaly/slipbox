#!/usr/bin/env python3
"""Reject forbidden /using-slipbox caller wording in operative Markdown."""
from pathlib import Path
import re
import sys

PATTERN = re.compile(
    r"Run `/using-slipbox`|through `/using-slipbox`|"
    r"\blog tension\b|\broute seed\b|"
    r"\.slipbox/bin/slipbox (?:links add|evergreen add)\b|"
    r"\bwork finalize\b"
)
QUOTE = (
    "Caller skills state the natural imperative action and append `/using-slipbox`.",
    "Write “Record the link `/using-slipbox`,” never “Run `/using-slipbox`” or",
    '“record the link through `/using-slipbox`.”',
)


def operative_lines(path: Path):
    lines = path.read_text(encoding="utf-8").splitlines()
    engine_scope = "skills/using-slipbox/" in path.as_posix()
    is_engine = path.as_posix().endswith("skills/using-slipbox/SKILL.md")
    if is_engine:
        exact_starts = [index for index in range(len(lines) - 2) if tuple(lines[index:index + 3]) == QUOTE]
        if len(exact_starts) != 1:
            raise ValueError(f"expected exactly one intact required caller quotation in {path}, found {len(exact_starts)}")
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
            if path.as_posix().endswith(("skills/make-reference-note/references/synthesis-map.md", "docs/slipbox-cli.md")):
                continue
            engine_scope = "skills/using-slipbox/" in path.as_posix()
            is_engine = path.as_posix().endswith("skills/using-slipbox/SKILL.md")
            try:
                for number, line in operative_lines(path):
                    if engine_scope and not is_engine:
                        continue
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
