/*  File:    sysfs/io.pl
    Author:  ,,,
    Created: Dec  9 2024
    Purpose:
*/

:- module(sysfs_io,
          [ sysfs_read/2,                       % +Abs,?Term
            sysfs_read/3,                       % +Type,+Abs,?Data
            sysfs_write/2,
            sysfs_chip/2,
            sysfs_chip/2
          ]).
:- autoload(library(readutil), [read_file_to_string/3, read_file_to_codes/3]).
:- autoload(library(strings), [string_lines/2]).
:- autoload(library(dcg/high_order), [sequence/4]).
:- use_module(endian).

:- multifile user:file_search_path/2.

user:file_search_path(sysfs, '/sys').
user:file_search_path(sysfs_class, sysfs(class)).

sysfs_encoding(ascii).

%!  sysfs_read(+Abs, ?Term) is semidet.
%!  sysfs_read(+Type, +Abs, ?Data) is semidet.
%!  sysfs_read(+Type, +File, +Directory, ?Data) is semidet.
%
%   Reads a Term from a file at Abs or reads File relative to Directory.
%
%   In practice, reading a file at Abs reads a line and attempts to read
%   a Prolog term from the resulting string. The term should be an atom
%   or number, else some other Prolog-term compatible string. There must
%   only be one line; otherwise, the read will fail.
%
%   The four-arity reading predicate accepts a data Type: a =term=,
%   =number=, =atom= or a list of =lines=.
%
%   Reads bytes, a number, an atom or lines of strings without attempting to
%   interpret the strings as Prolog terms.

sysfs_read(Abs, Term) :-
    Term =.. [File, Data],
    sysfs_read(term, Abs/File, Data).

sysfs_read(term, Abs, Data) :-
    sysfs_read(lines, Abs, [Line]),
    term_string(Data, Line).
sysfs_read(bytes, Abs, Data) :-
    read_file_to_codes(Abs, Data, [type(binary), file_errors(fail)]).
sysfs_read(number, Abs, Data) :-
    sysfs_read(lines, Abs, [Line]),
    number_string(Data, Line).
sysfs_read(atom, Abs, Data) :-
    sysfs_read(lines, Abs, [Line]),
    atom_string(Data, Line).
sysfs_read(lines, Abs, Data) :-
    sysfs_encoding(Encoding),
    read_file_to_string(Abs, String, [encoding(Encoding), file_errors(fail)]),
    string_lines(String, Data).
sysfs_read(big(Width), Abs, Data) :-
    sysfs_read(bytes, Abs, Bytes),
    phrase(sequence(big_endian(Width), Data), Bytes).
sysfs_read(little(Width), Abs, Data) :-
    sysfs_read(bytes, Abs, Bytes),
    phrase(sequence(little_endian(Width), Data), Bytes).

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

sysfs_write(Abs, Term) :-
    Term =.. [File, Data],
    absolute_file_name(Abs, Abs0),
    absolute_file_name(Abs0/File, Abs_, [access(write), file_errors(fail)]),
    sysfs_encoding(Encoding),
    setup_call_cleanup(
        open(Abs_, write, Stream, [encoding(Encoding)]),
        write(Stream, Data),
        close(Stream)).

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

sysfs_chip(Type, Chip), var(Chip) =>
    atomic_list_concat([Type, chip, *], Pattern),
    absolute_file_name(sysfs_class(Type/Pattern), WildCard),
    absolute_file_name(WildCard,
                       Chip,
                       [ file_type(directory),
                         expand(true),
                         solutions(all)
                       ]).
sysfs_chip(Type, Chip) =>
    absolute_file_name(sysfs_class(Type), Abs),
    directory_file_path(Abs, File, Chip),
    atomic_concat(Type, chip, File0),
    atom_concat(File0, _, File),
    exists_directory(Chip).
