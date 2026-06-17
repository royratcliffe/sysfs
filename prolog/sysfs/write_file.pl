/*  File:    sysfs/write_file.pl
    Author:  Roy Ratcliffe
    Created: Dec  9 2024
    Purpose: Writing Files in sysfs or Elsewhere

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

:- module(sysfs_write_file,
          [ write_file_as/2, % +File, +Term
            write_file_as/3  % +As, +File, -Data
          ]).
:- autoload(library(dcg/high_order), [sequence//2]).
:- use_module(endian).
:- use_module(hex).

%!  write_file_as(+File, +Term) is semidet.
%!  write_file_as(+As, +File, +Data) is semidet.
%
%   Writes a Term to a file at File. The Term is a Prolog term that specifies how
%   to write the file. The first argument of the term is the name of the write
%   method, and the remaining arguments are the parameters for that method. The
%   write methods are defined as follows:
%
%       - term: writes a Prolog term to the file. The Data variable should be a
%         Prolog term, and it will be converted to a string and written to the file
%         as a single line.
%       - bytes: writes a list of bytes (codes) to the file. The Data variable
%         should be a list of codes, and it will be written to the file as binary
%         data.
%       - number: writes a number to the file. The Data variable should be a number,
%         and it will be converted to a string and written to the file as a single
%         line.
%       - atom: writes an atom to the file. The Data variable should be an atom, and
%         it will be converted to a string and written to the file as a single line.
%       - lines: writes a list of lines to the file. The Data variable should be a
%         list of strings, and each string will be written to the file as a separate
%         line.
%       - line: writes a single line to the file. The Data variable should be a
%         string, and it will be written to the file as a single line.
%       - bigs(Width): writes a sequence of big-endian integers of the
%         specified Width (in bits) to the file. The Data variable should be
%         a list of integers, and each integer will be converted to a
%         sequence of bytes in big-endian format and written to the file as
%         binary data.
%       - big(Width): writes a big-endian integer of the specified Width (in bits)
%         to the file. The Data variable should be an integer, and it will be
%         converted to a list of bytes in big-endian format and written to the file
%         as binary data.
%       - littles(Width): writes a sequence of little-endian integers of the
%         specified Width (in bits) to the file. The Data variable should be a list
%         of integers, and each integer will be converted to a sequence of bytes in
%         little-endian format and written to the file as binary data.
%       - little(Width): writes a little-endian integer of the specified Width (in
%         bits) to the file. The Data variable should be an integer, and it will be
%         converted to a list of bytes in little-endian format and written to the
%         file as binary data.
%
%   @arg File is the path to the file in the file system.
%
%   @arg As is a Prolog term that specifies how to write the file, as described above.
%
%   @arg Term is the name of the write method, as described above.
%
%   @arg Data is the data to write to the file, which should be unified
%   according to the specified write method.

write_file_as(File, Term) :-
    Term =.. [As, Data],
    !,
    as(As, File, Data).
write_file_as(File, Term) :-
    Term =.. [Name, Arg, Data],
    As =.. [Name, Arg],
    as(As, File, Data).

write_file_as(As, File, Data) :- as(As, File, Data).

:- multifile as/3.

as(term, File, Data) :-
    term_string(Data, Line),
    as(line, File, Line).
as(bytes, File, Data) :-
    absolute_file_name(File, Abs, [file_errors(fail), access(write)]),
    write_bytes_to_file(Abs, Data, [file_errors(fail), type(binary)]),
    (   debugging(write(file))
    ->  bytes_to_hex(Data, ' ', HexString),
        debug(write(file), 'Wrote bytes to file: ~w~n~s---', [File, HexString])
    ;   true
    ).
as(number, File, Data) :-
    number_string(Data, Line),
    as(line, File, Line).
as(atom, File, Data) :-
    atom_string(Data, Line),
    as(line, File, Line).
as(lines, File, Data) :-
    string_lines(String, Data),
    absolute_file_name(File, Abs, [file_errors(fail), access(write)]),
    write_string_to_file(Abs, String, [file_errors(fail)]),
    debug(write(file), 'Wrote string to file: ~w~n~s---', [File, String]).
as(line, File, Data) :-
    as(lines, File, [Data]).
as(bigs(Width), File, Data) :-
    once(phrase(sequence(big_endian(Width), Data), Bytes)),
    as(bytes, File, Bytes).
as(big(Width), File, Data) :-
    as(bigs(Width), File, [Data]).
as(littles(Width), File, Data) :-
    once(phrase(sequence(little_endian(Width), Data), Bytes)),
    as(bytes, File, Bytes).
as(little(Width), File, Data) :-
    as(littles(Width), File, [Data]).

%! write_bytes_to_file(+File, +Bytes, +Options) is semidet.
% Writes a list of bytes (codes) to a file. The File is the path to the file,
% Bytes is a list of codes to write, and Options is a list of options for
% opening the file. The file is opened in binary mode, and the bytes are
% written to the file as binary data. The file is closed after writing.
write_bytes_to_file(File, Bytes, Options) :-
    setup_call_cleanup(open(File, write, Stream, Options),
                       maplist(put_byte(Stream), Bytes),
                       close(Stream)).

%! write_string_to_file(+File, +String, +Options) is semidet.
% Writes a single string to a file. The File is the path to the file, String is
% the string to write, and Options is a list of options for opening the file.
% The file is opened in text mode, and the string is written to the file as a
% single line. The file is closed after writing.
write_string_to_file(File, String, Options) :-
    setup_call_cleanup(open(File, write, Stream, Options),
                       write(Stream, String),
                       close(Stream)).
