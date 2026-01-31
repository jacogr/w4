BEGIN { in_def = 0; def_name = ""; buf = "" }

function flush() {
  if (buf != "") { print buf; buf = "" }
}

function trim(s) {
  sub(/^[[:space:]]+/, "", s)
  sub(/[[:space:]]+$/, "", s)
  return s
}

# Return 1 if line ends the current definition (based on tokens on THIS line)
function line_ends_def(line,    n) {
  # Special-case: defining the word named ';'
  # Only end on a "standalone" terminator line: ';' or '; immediate'
  if (def_name == ";") {
    return (line ~ /^;([[:space:]]+immediate)?$/)
  }

  # Tokenize the (already stripped) line
  n = split(line, t, /[[:space:]]+/)

  # End forms:
  #   ... ;
  #   ... ; immediate
  #
  # But DO NOT treat "postpone ;" as a terminator.
  if (n >= 1 && t[n] == ";") {
    if (n >= 2 && t[n-1] == "postpone") return 0
    return 1
  }

  if (n >= 2 && t[n] == "immediate" && t[n-1] == ";") {
    if (n >= 3 && t[n-2] == "postpone") return 0
    return 1
  }

  return 0
}

{
  line = trim($0)
  if (line == "") next

  if (!in_def) {
    # Start of colon definition
    if (line ~ /^:[[:space:]]*/) {
      in_def = 1
      buf = line

      # Extract def name: first token after ':'
      tmp = line
      sub(/^:[[:space:]]*/, "", tmp)
      split(tmp, a, /[[:space:]]+/)
      def_name = a[1]  # can be ';'

      # Single-line def ends immediately (using same end logic)
      if (line_ends_def(line)) {
        in_def = 0
        def_name = ""
        flush()
      }
    } else {
      print line
    }
    next
  }

  # Inside a definition: append this line
  buf = buf " " line

  # End definition only if THIS line is a real terminator line
  if (line_ends_def(line)) {
    in_def = 0
    def_name = ""
    flush()
  }
}

END { flush() }
