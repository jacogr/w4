#!/usr/bin/awk -f

# Generate $__internal_execute_asm from builtin elem table entries.
# Usage:
#   awk -f scripts/exec-asm.awk -v src=wat/forth/builtins.wat -v out=build/w4-exec-asm.wat

BEGIN {
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

  for (i = 0; i <= max_idx; i++) {
    printf "\t(if (i32.eq (local.get $idx) (i32.const %d))\n", i >> out
    printf "\t\t(then (call %s))\n", funcs[i] >> out
    printf "\t\t(else\n" >> out
  }

  printf "\t\t\t(call $__assert (i32.const 0) (i32.const -12))\n" >> out

  for (i = 0; i <= max_idx; i++) {
    printf "\t\t\t)\n" >> out
  }

  # Close the nested "(if ...)" wrappers.
  close_ifs = "\t"
  for (i = 0; i <= max_idx; i++) {
    close_ifs = close_ifs ")"
  }
  print close_ifs >> out

  print ")" >> out
  close(out)
}
