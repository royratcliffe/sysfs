:- begin_tests(sysfs_endian).
:- use_module(endian).

test(endian, [true(v(A, B, C, D)==v(16, [C, D], C, D))]) :-
    sysfs_endian:endianness(A, B, [C, D], []).

test(big_endian, [true(v(A, B) == v(16, 16'ff00))]) :-
    phrase(sysfs_endian:big_endian(A, B), [255, 0]).

test(big_endian_, [true(v(A, B, C)==v(0, 100, 0))]) :-
    sysfs_endian:big_endian_([A, B], 100, C).

test(little_endian, [true(v(A, B) == v(16, 16'ff))]) :-
    phrase(sysfs_endian:little_endian(A, B), [255, 0]).

test(little_endian_, [true(v(A, B, C)==v(100, 0, 0))]) :-
    sysfs_endian:little_endian_([A, B], 100, C).

:- end_tests(sysfs_endian).
