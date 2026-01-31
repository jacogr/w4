# tabs -> single space
s/[	][	]*/ /g

# trim leading whitespace
s/^[[:space:]]*//

# remove stack-effect comments repeatedly
:a
s/(^|[[:space:]])\([[:space:]][^)]*--[^)]*[[:space:]]\)[[:space:]]*/\1/
ta

# keep definition of '\' as a word
/^[[:space:]]*:[[:space:]]*\\[[:space:]]/b

# strip inline "\" comments only when "\" is a standalone token (space \ space)
s/[[:space:]]+\\[[:space:]].*$//

# drop blank lines + full-line "\" comments
/^[[:space:]]*$/d
/^[[:space:]]*\\/d
