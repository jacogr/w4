#!/usr/bin/awk -f

# Generate a WAT fragment embedding ASCII Forth source into linear memory.
# Usage:
#   awk -f scripts/embed-forth.awk -v src=<input.f> -v out=<output.wat>

BEGIN {
  # Use decimal for portability across awk variants (some treat 0x... as 0).
  MEM_TOP = 4194304

  if (src == "" || out == "") {
    print "usage: awk -f embed-forth.awk -v src=<w4.f> -v out=<out.wat>" > "/dev/stderr"
    exit 2
  }

  # ASCII lookup map for ord().
  for (i = 1; i < 128; i++) {
    ORD[sprintf("%c", i)] = i
  }

  # Exact file size in bytes.
  cmd = "wc -c < \"" src "\""
  cmd | getline file_size
  close(cmd)
  gsub(/^[ \t]+|[ \t]+$/, "", file_size)

  if (file_size !~ /^[0-9]+$/) {
    print "error: failed to determine file size for " src > "/dev/stderr"
    exit 1
  }

  payload_size = file_size + 1
  start = MEM_TOP - payload_size - 1

  if (start < 0) {
    printf "error: payload too large (%d bytes) for MEM_TOP=0x%x\n", payload_size, MEM_TOP > "/dev/stderr"
    exit 1
  }

  print ";; embedded forth source: " basename(src) > out
  print ";; size (bytes, incl NUL): " payload_size >> out
  printf ";; start = 0x%08x (MEM_TOP=0x%08x - size)\n\n", start, MEM_TOP >> out

  print "(global $W4_FORTH_START (mut i32) (i32.const " start "))" >> out
  print "(global $W4_FORTH_SIZE  (mut i32) (i32.const " payload_size "))" >> out
  print "" >> out
  print "(data (i32.const " start ")" >> out

  consumed = 0
  while ((getline line < src) > 0) {
    escaped = escape_ascii(line)
    consumed += length(line)

    # If we have remaining bytes, this record had a trailing LF in the source.
    if (consumed < file_size) {
      escaped = escaped "\\0a"
      consumed++
    }

    print "  \"" escaped "\"" >> out
  }
  close(src)

  # Explicit NUL terminator.
  print "  \"\\00\"" >> out
  print ")" >> out

  close(out)
}

function escape_ascii(s,    i, ch, code, out_s) {
  out_s = ""

  for (i = 1; i <= length(s); i++) {
    ch = substr(s, i, 1)
    code = ord(ch)

    # Printable ASCII except '"' (34) and '\' (92).
    if (code >= 32 && code <= 126 && code != 34 && code != 92) {
      out_s = out_s ch
    } else {
      out_s = out_s "\\" tohex2(code)
    }
  }

  return out_s
}

function ord(ch) {
  return (ch in ORD) ? ORD[ch] : 63
}

function tohex2(n,    d, hi, lo) {
  d = "0123456789abcdef"
  hi = int(n / 16)
  lo = n % 16
  return substr(d, hi + 1, 1) substr(d, lo + 1, 1)
}

function basename(p,    a, n) {
  n = split(p, a, "/")
  return a[n]
}
