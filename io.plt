:- begin_tests(sys_io).
:- use_module(io).

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Converting a string into lines  using string_lines/2 functions correctly
for non-terminated lines. An empty string results  in zero lines. One or
two newlines produce one or two lines,  respectively. A string without a
newline but containing content yields one line.

?- string_lines("", A).
A = [].

?- string_lines("\n", A).
A = [""].

?- string_lines("\n\n", A).
A = ["", ""].

?- string_lines("a", A).
A = ["a"].

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

test(string_lines, A == []) :- string_lines("", A).

:- end_tests(sys_io).
