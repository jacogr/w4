{
	line = $0

	# tabs -> single space  (s/[\t][\t]*/ /g)
	gsub(/\t+/, " ", line)

	# trim leading whitespace (s/^[[:space:]]*//)
	sub(/^[[:space:]]*/, "", line)

	# remove stack-effect comments repeatedly, preserving (^|space)
	# sed:
	#   :a
	#   s/(^|[[:space:]])\([[:space:]][^)]*--[^)]*[[:space:]]\)[[:space:]]*/\1/
	#   ta
	while (match(line, /(^|[[:space:]])\([[:space:]][^)]*--[^)]*[[:space:]]\)[[:space:]]*/)) {
		pre  = substr(line, 1, RSTART - 1)
		m    = substr(line, RSTART, RLENGTH)
		post = substr(line, RSTART + RLENGTH)

		# "\1" is either "" (if start-of-line) or the single whitespace char
		keep = ""
		c = substr(m, 1, 1)
		if (c ~ /[[:space:]]/) keep = c

		line = pre keep post
	}

	# keep definition of '\' as a word
	# sed: /^[[:space:]]*:[[:space:]]*\\[[:space:]]/b
	if (line !~ /^:[[:space:]]*\\[[:space:]]/) {
		# strip inline "\" comments only when "\" is a standalone token (space \ space)
		# sed: s/[[:space:]]+\\[[:space:]].*$//
		sub(/[[:space:]]+\\[[:space:]].*$/, "", line)
	}

	# drop blank lines + full-line "\" comments
	# sed: /^[[:space:]]*$/d
	#      /^[[:space:]]*\\/d
	if (line ~ /^[[:space:]]*$/) next
	if (line ~ /^[[:space:]]*\\/) next

	print line
}
