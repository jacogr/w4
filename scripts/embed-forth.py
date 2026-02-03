#!/usr/bin/env python3
from __future__ import annotations

import sys
from pathlib import Path

MEM_TOP = 0x00100000  # top-of-memory for embedding


def wat_escape_bytes(b: bytes) -> str:
    """
    Emit a WAT string literal body (no surrounding quotes).
    Use:
      - printable ASCII as-is (except " and \\)
      - hex escapes for everything else (including newline and NUL)
    WAT supports \\hh (two hex digits).
    """
    out: list[str] = []
    for x in b:
        if 0x20 <= x <= 0x7E and x not in (0x22, 0x5C):  # printable, not " or \
            out.append(chr(x))
        else:
            out.append(f"\\{x:02x}")
    return "".join(out)


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: embed_forth.py <w4.f> <out.wat>", file=sys.stderr)
        return 2

    src_path = Path(sys.argv[1])
    out_path = Path(sys.argv[2])

    data = src_path.read_bytes()

    # payload = file bytes + trailing NUL
    payload_size = len(data) + 1
    start = MEM_TOP - payload_size -1
    if start < 0:
        print(
            f"error: payload too large ({payload_size} bytes) "
            f"for MEM_TOP=0x{MEM_TOP:x}",
            file=sys.stderr,
        )
        return 1

    # Split exactly on LF so we emit one WAT string per Forth line
    raw_lines = data.split(b"\n")

    wat_strings: list[str] = []
    for i, raw in enumerate(raw_lines):
        # Re-append newline if it existed
        if i < len(raw_lines) - 1:
            raw = raw + b"\n"

        # Skip a final empty fragment if the file ended with '\n'
        if raw == b"":
            continue

        wat_strings.append(wat_escape_bytes(raw))

    # Append explicit NUL terminator
    wat_strings.append("\\00")

    # Emit WAT fragment
    lines_out: list[str] = []
    lines_out.append(f";; embedded forth source: {src_path.name}")
    lines_out.append(f";; size (bytes, incl NUL): {payload_size}")
    lines_out.append(
        f";; start = 0x{start:08x} (MEM_TOP=0x{MEM_TOP:08x} - size)"
    )
    lines_out.append("")
    lines_out.append(f"(global $W4_FORTH_START (mut i32) (i32.const {start}))")
    lines_out.append(f"(global $W4_FORTH_SIZE  (mut i32) (i32.const {payload_size}))")
    lines_out.append("")
    lines_out.append(f"(data (i32.const {start})")
    for s in wat_strings:
        lines_out.append(f'  "{s}"')
    lines_out.append(")")
    lines_out.append("")

    out_path.write_text("\n".join(lines_out), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
