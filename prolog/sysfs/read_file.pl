/*  File:    sysfs/read_file.pl
    Author:  Roy Ratcliffe
    Created: Dec  9 2024
    Purpose: Reading Files in sysfs or Elsewhere

Copyright (c) 2024, Roy Ratcliffe, Northumberland, United Kingdom

Permission is hereby granted, free of charge,  to any person obtaining a
copy  of  this  software  and    associated   documentation  files  (the
"Software"), to deal in  the   Software  without  restriction, including
without limitation the rights to  use,   copy,  modify,  merge, publish,
distribute, sub-license, and/or sell copies  of   the  Software,  and to
permit persons to whom the Software is   furnished  to do so, subject to
the following conditions:

    The above copyright notice and this permission notice shall be
    included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT  WARRANTY OF ANY KIND, EXPRESS
OR  IMPLIED,  INCLUDING  BUT  NOT   LIMITED    TO   THE   WARRANTIES  OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR   PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS  OR   COPYRIGHT  HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY,  WHETHER   IN  AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM,  OUT  OF   OR  IN  CONNECTION  WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/

:- module(sysfs_read_file,
          [ read_file_as/2, % +File, +Term
            read_file_as/3  % +As, +File, -Data
          ]).
:- autoload(library(readutil), [read_file_to_string/3, read_file_to_codes/3]).
:- autoload(library(strings), [string_lines/2]).
:- autoload(library(dcg/high_order), [sequence//2]).
:- use_module(library(sysfs), []).
:- use_module(endian).
:- use_module(hex).

%!  read_file_as(+File, +Term) is semidet.
%!  read_file_as(+As, +File, -Data) is semidet.
%
%   Reads a Term from a file at File. Reads bytes, a number, an atom or lines of
%   strings without attempting to interpret the strings as Prolog, not unless
%   Term is of the form term(_).
%
%   The Term is a Prolog term that specifies how to read the file. The first
%   argument of the term is the name of the read method, and the remaining
%   arguments are the parameters for that method. The read methods are defined
%   as follows:
%
%       - `term`: reads the file as a Prolog term. The file should contain a single
%         line that represents a Prolog term. The term is unified with the Data
%         variable.
%       - `bytes`: reads the file as a list of bytes (codes). The file is treated as a
%         binary file, and the contents are unified with the Data variable as a list
%         of codes.
%       - `number`: reads the file as a number. The file should contain a single line
%         that represents a number. The number is unified with the Data variable.
%       - `atom`: reads the file as an atom. The file should contain a single line
%         that represents an atom. The atom is unified with the Data variable.
%       - `lines`: reads the file as a list of lines. The file is treated as a text
%         file, and the contents are unified with the Data variable as a list of
%         lines (strings).
%       - `line`: reads the file as a single line. The file is treated as a text file,
%         and the contents are unified with the Data variable as a single line (string).
%       - bigs(Width): reads the file as a sequence of big-endian integers of the
%         specified Width (in bits). The file is treated as a binary file, and the
%         contents are interpreted as a sequence of big-endian integers. The list of
%         integers is unified with the Data variable.
%       - big(Width): reads the file as a big-endian integer of the specified Width
%         (in bits). The file is treated as a binary file, and the contents are
%         interpreted as a big-endian integer. The integer is unified with the Data
%         variable.
%       - littles(Width): reads the file as a sequence of little-endian integers of the
%         specified Width (in bits). The file is treated as a binary file, and the
%         contents are interpreted as a sequence of little-endian integers. The list of
%         integers is unified with the Data variable.
%       - little(Width): reads the file as a little-endian integer of the specified
%         Width (in bits). The file is treated as a binary file, and the contents
%         are interpreted as a little-endian integer. The integer is unified with
%         the Data variable.
%
%   @arg File is the path to the file in the file system.
%
%   @arg Term is a Prolog term that specifies how to read the file, as described above.
%
%   @arg As is the name of the read method, as described above.
%
%   @arg Data is the data read from the file, unified according to the specified
%   read method.

read_file_as(File, Term) :-
    Term =.. [As, Data],
    !,
    as(As, File, Data).
read_file_as(File, Term) :-
    Term =.. [Name, Arg, Data],
    As =.. [Name, Arg],
    as(As, File, Data).

read_file_as(As, File, Data) :- as(As, File, Data).

% The as/3 predicate is defined as a multifile predicate, which allows it to be
% extended with additional read methods in other modules. Each read-as method is
% defined as a clause of the as/3 predicate, and the first argument specifies
% the name of the read method. The as/3 predicate is called by read_file_as/2 to
% perform the actual reading of the file based on the specified read method. The
% as/3 predicate is semidet, meaning that it will succeed if the file is read
% successfully according to the specified method, and fail otherwise. The as/3
% predicate is also deterministic, meaning that it will not leave a choice point
% after succeeding, as each read method is designed to read the file in a
% specific way and will not produce multiple results for the same file and
% method.
:- multifile as/3.

as(term, File, Data) :-
    as(line, File, Line),
    term_string(Data, Line).
as(bytes, File, Data) :-
    absolute_file_name(File, Abs, [file_errors(fail), access(read)]),
    read_file_to_codes(Abs, Data, [file_errors(fail), type(binary)]),
    (   debugging(read(file))
    ->  bytes_to_hex(Data, ' ', HexString),
        debug(read(file), 'Read bytes from file: ~w~n~s', [File, HexString])
    ;   true
    ).
as(number, File, Data) :-
    as(line, File, Line),
    number_string(Data, Line).
as(atom, File, Data) :-
    as(line, File, Line),
    atom_string(Data, Line).
as(lines, File, Data) :-
    absolute_file_name(File, Abs, [file_errors(fail), access(read)]),
    read_file_to_string(Abs, String, [file_errors(fail)]),
    debug(read(file), 'Read string from file: ~w~n~s---', [File, String]),
    string_lines(String, Data).
as(line, File, Data) :-
    as(lines, File, [Data]).
as(bigs(Width), File, Data) :-
    as(bytes, File, Bytes),
    once(phrase(sequence(big_endian(Width), Data), Bytes)).
as(big(Width), File, Data) :-
    as(bigs(Width), File, [Data]).
as(littles(Width), File, Data) :-
    as(bytes, File, Bytes),
    once(phrase(sequence(little_endian(Width), Data), Bytes)).
as(little(Width), File, Data) :-
    as(littles(Width), File, [Data]).
