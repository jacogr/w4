#!/usr/bin/awk -f

# Generate $__internal_execute_asm from builtin elem table entries.
# Usage:
#   awk -f scripts/exec-asm.awk -v src=wat/forth/builtins.wat -v out=build/w4-exec-asm.wat

BEGIN {
  MAX_BUILTIN_INDEX = 31

  if (src == "" || out == "") {
    print "usage: awk -f exec-asm.awk -v src=<builtins.wat> -v out=<out.wat>" > "/dev/stderr"
    exit 2
  }
}

{
  # Match lines such as:
  #   (elem (i32.const  0) $__forth_fn_exit)
  # and ignore trailing comments.
  if ($1 == "(elem" && $2 == "(i32.const" && $4 ~ /^\$__forth_fn_[A-Za-z0-9_]+\)/) {
    idx = $3
    gsub(/\)/, "", idx)

    fn = $4
    gsub(/\)/, "", fn)

    if (idx !~ /^[0-9]+$/) {
      printf "error: invalid builtin index '%s' in %s\n", idx, src > "/dev/stderr"
      exit 1
    }

    seen[idx] = 1
    funcs[idx] = fn
    if (idx + 0 > max_idx) {
      max_idx = idx + 0
    }
    count++
  }
}

END {
  if (count == 0) {
    printf "error: no builtin elem entries found in %s\n", src > "/dev/stderr"
    exit 1
  }

  if (max_idx > MAX_BUILTIN_INDEX) {
    printf "error: builtin elem index %d exceeds max supported %d (table size 32) in %s\n", max_idx, MAX_BUILTIN_INDEX, src > "/dev/stderr"
    exit 1
  }

  # Require dense 0..max to keep dispatch predictable.
  for (i = 0; i <= max_idx; i++) {
    if (!seen[i]) {
      printf "error: missing builtin elem index %d in %s\n", i, src > "/dev/stderr"
      exit 1
    }
  }

  print ";; auto-generated from " src > out
  print ";; do not edit manually" >> out
  print "(func $__internal_execute_asm (param $idx i32)" >> out
  print "\t(block $done" >> out
  print "\t\t(block $invalid" >> out

  indent = "\t\t\t"
  for (i = max_idx; i >= 0; i--) {
    printf "%s(block $c%d\n", indent, i >> out
    indent = indent "\t"
  }

  printf "%s(local.get $idx)\n", indent >> out
  printf "%s(br_table", indent >> out
  for (i = 0; i <= max_idx; i++) {
    printf " $c%d", i >> out
  }
  print " $invalid)" >> out

  for (i = 0; i <= max_idx; i++) {
    indent = substr(indent, 1, length(indent) - 1)
    printf "%s)\n", indent >> out
    printf "%s(call %s)\n", indent, funcs[i] >> out
    printf "%s(br $done)\n", indent >> out
  }

  print "\t\t)" >> out
  print "\t\t(call $__assert (i32.const 0) (i32.const -12))" >> out
  print "\t)" >> out
  print ")" >> out
  close(out)
}
