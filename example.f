testing

: foo
	true if
		$11
	else
		$22
	then

	5 0 do
		i u.
	loop

	3 0 ?do
		i u.
		true if
			." true " cr
		else
			." false " cr
		then
	loop

	\ true if
	\ 		." t true " cr
	\ 	else
	\ 		." t false " cr
	\ 	then
;

\ see foo

\ foo
words

.sa
