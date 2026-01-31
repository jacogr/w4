BEGIN { in_def = 0; buf = "" }

function flush() {
  if (buf != "") { print buf; buf = "" }
}

{
  line = $0
  sub(/^[[:space:]]+/, "", line)
  sub(/[[:space:]]+$/, "", line)
  if (line == "") next

  if (!in_def) {
    # Start of colon definition
    if (line ~ /^:[[:space:]]/) {
      in_def = 1
      buf = line

      # Single-line def ends immediately
      if (buf ~ /(^|[[:space:]]);([[:space:]]|$)/) {
        in_def = 0
        flush()
      }
    } else {
      # Pass through non-definition lines unchanged
      print line
    }
    next
  }

  # Inside a definition: append
  buf = buf " " line

  # End definition at ';' token
  if (buf ~ /(^|[[:space:]]);([[:space:]]|$)/) {
    in_def = 0
    flush()
  }
}

END { flush() }
