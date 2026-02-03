BEGIN {
	mode = 0        # 0 normal, 1 colon_def, 2 create_block
	def_name = ""
	buf = ""
}

function flush() {
	if (buf != "") { print buf; buf = "" }
}

function trim(s) {
	sub(/^[[:space:]]+/, "", s)
	sub(/[[:space:]]+$/, "", s)
	return s
}

# Return 1 if line ends the current colon definition (based on tokens on THIS line)
function line_ends_def(line, n) {
	# Special-case: defining the word named ';'
	# Only end on a "standalone" terminator line: ';' or '; immediate'
	if (def_name == ";") {
		return (line ~ /^;([[:space:]]+immediate)?$/)
	}

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

function is_colon_start(line) {
	return (line ~ /^:[[:space:]]*/)
}

function is_create_start(line) {
	return (line ~ /^create([[:space:]]|$)/)
}

function is_block_start(line) {
	# create-block ends when the next block starts with ':' or 'create'
	return (is_colon_start(line) || is_create_start(line))
}

{
	line = trim($0)
	if (line == "") next

	reprocess = 1
	while (reprocess) {
		reprocess = 0

		# -------------------------
		# create_block state
		# -------------------------
		if (mode == 2) {
			# If we hit the next block start, flush create block and re-handle this line
			if (is_block_start(line)) {
				mode = 0
				flush()
				reprocess = 1
				continue
			}

			# Otherwise keep appending into the create block
			buf = buf " " line
			next
		}

		# -------------------------
		# normal state
		# -------------------------
		if (mode == 0) {
			# Start a colon definition
			if (is_colon_start(line)) {
				mode = 1
				buf = line

				# Extract def name: first token after ':'
				tmp = line
				sub(/^:[[:space:]]*/, "", tmp)
				split(tmp, a, /[[:space:]]+/)
				def_name = a[1]  # can be ';'

				# Single-line def ends immediately
				if (line_ends_def(line)) {
					mode = 0
					def_name = ""
					flush()
				}

				next
			}

			# Start a create block
			if (is_create_start(line)) {
				mode = 2
				buf = line
				next
			}

			# Pass through other lines unchanged
			print line
			next
		}

		# -------------------------
		# colon_def state
		# -------------------------
		if (mode == 1) {
			buf = buf " " line

			if (line_ends_def(line)) {
				mode = 0
				def_name = ""
				flush()
			}

			next
		}
	}
}

END { flush() }
