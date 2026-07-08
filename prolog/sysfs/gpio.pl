/*  File:    sysfs/gpio.pl
    Author:  Roy Ratcliffe
    Created: Dec  9 2024
    Purpose: Linux GPIO Access in sysfs

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

:- module(sysfs_gpio,
          [ sysfs_gpio_export/4, % ?Chip, ?Offset, -Export, -Line
            sysfs_gpio_unexport/4, % ?Chip, ?Offset, -Export, -Line
            sysfs_gpio_exported/4, % ?Chip, ?Offset, -Export, -Line
            sysfs_gpio_ensure_exported/4, % ?Chip, ?Offset, -Export, -Line
            sysfs_gpio_ensure_unexported/4, % ?Chip, ?Offset, -Export, -Line
            sysfs_gpio_read/3, % ?File, ?Line, -Data
            sysfs_gpio_read/4, % ?File, ?Chip, ?Offset, -Data
            sysfs_gpio_write/3, % ?File, ?Line, +Data
            sysfs_gpio_write/4, % ?File, ?Chip, ?Offset, +Data
            sysfs_gpio_line/4 % ?Chip, ?Offset, -Export, -Line
          ]).
:- use_module(library(sysfs)).
:- use_module(library(sysfs/gpiochip)).
:- use_module(library(sysfs/read_file)).
:- use_module(library(sysfs/write_file)).

/** <module> Linux GPIO Access in sysfs
 *
 * This module provides predicates to access GPIO lines in the sysfs
 * file system. It allows developers to export and unexport GPIO lines,
 * check if a line is exported, read values from files in the GPIO line
 * directory, and write values to files in the GPIO line directory. The
 * predicates are designed to be flexible and can be used in various
 * ways to access GPIO line information and control GPIO lines in the
 * sysfs virtual file system.
 *
 * ## Chips and Lines
 *
 * In sysfs, GPIO lines are organised into chips, which are represented
 * as directories in the gpio class of sysfs. Each chip has a base
 * number and a number of lines (ngpio). The lines in a chip are
 * numbered from the base number to the base number plus ngpio minus
 * one. To access a specific line, you need to know the chip it belongs
 * to and its offset within the chip. The offset is the number of the
 * line within the chip, starting from zero. For example, if a chip has
 * a base number of 100 and ngpio of 32, then the lines in that chip are
 * numbered from 100 to 131, and the offset of line gpio105 would be 5.
 * When you export a line, a symbolic link is created in the gpio class
 * of sysfs with the name 'gpio<Export>', where <Export> is the export
 * number for the line, which is calculated by adding the offset to the
 * base number of the chip. This symbolic link can be used to access the
 * line in the sysfs virtual file system, and files such as value,
 * direction, etc. can be read from or written to control the line. The
 * predicates in this module allow you to work with GPIO lines by
 * specifying the chip and offset, or by specifying the line name
 * directly. The predicates are designed to be flexible and can be used
 * in various ways to access and control GPIO lines in sysfs.
 *
 * @author Roy Ratcliffe
 */

%! sysfs_gpio_export_entry(-Entry) is nondet.
% Finds the export entry in the gpio class of sysfs. This is used to determine
% if the export entry exists, which is necessary for exporting GPIO lines.
sysfs_gpio_export_entry(Entry) :- sysfs_entry(gpio, Entry, [export]).

%!  sysfs_gpio_export(?Chip, ?Offset, -Export, -Line) is nondet.
%
%   Exports a GPIO line by writing its export number to the export pseudo-file
%   in the gpio class of sysfs.
%
%   Note that exporting only requests the kernel to export the line, and does
%   not guarantee that the line is actually exported. There will be a delay
%   between the time the export request is made and the time the line is
%   actually exported, which can be observed by checking if the symbolic link
%   for the line exists in the gpio class of sysfs. If the symbolic link does
%   not exist after a reasonable amount of time, then there may have been an
%   error exporting the line.
%
%   @arg Chip is the name of the GPIO chip, such as gpiochip0, gpiochip1, etc.
%   @arg Offset is the offset of the GPIO line within the chip. This is a
%   number that is added to the base number of the chip to calculate the export
%   number for the line.
%   @arg Export is the export number for the GPIO line, which is calculated by
%   adding the Offset to the Base number of the Chip. This is the number that is
%   written to the export pseudo-file in the gpio class of sysfs to export the
%   line, and is also used in the name of the symbolic link that is created in
%   the gpio class of sysfs when the line is exported.
%   @arg Line is the name of the GPIO line, which is constructed as
%   'gpio<Export>', where <Export> is the Export number for the line. This is
%   the name of the symbolic link that is created in the gpio class of sysfs
%   when the line is exported, and can be used to access the line in the sysfs
%   virtual file system.

sysfs_gpio_export(Chip, Offset, Export, Line) :-
    sysfs_gpio_line(Chip, Offset, Export, Line),
    write_file_as(sysfs_class_gpio(export), number(Export)).

%!  sysfs_gpio_unexport(?Chip, ?Offset, -Export, -Line) is nondet.
%
%   Unexports a GPIO line by writing its export number to the unexport
%   pseudo-file in the gpio class of sysfs.
%
%   @arg Chip is the name of the GPIO chip, such as gpiochip0, gpiochip1, etc.
%   @arg Offset is the offset of the GPIO line within the chip. This is
%   a number that is added to the base number of the chip to calculate
%   the export number for the line.
%   @arg Export is the export number for the GPIO line, which is
%   calculated by adding the Offset to the Base number of the Chip. This
%   is the number that is written to the unexport pseudo-file in the
%   gpio class of sysfs to unexport the line, and is also used in the
%   name of the symbolic link that is created in the gpio class of sysfs
%   when the line is exported.
%   @arg Line is the name of the GPIO line, which is constructed as
%   'gpio<Export>', where <Export> is the Export number for the line.
%   This is the name of the symbolic link that is created in the gpio
%   class of sysfs when the line is exported, and can be used to access
%   the line in the sysfs virtual file system.

sysfs_gpio_unexport(Chip, Offset, Export, Line) :-
    sysfs_gpio_line(Chip, Offset, Export, Line),
    write_file_as(sysfs_class_gpio(unexport), number(Export)).

%!  sysfs_gpio_exported(?Chip, ?Offset, -Export, -Line) is nondet.
%
%   Checks if a GPIO line is exported by checking if the symbolic link
%   for the line exists in the gpio class of sysfs. The symbolic link is
%   named 'gpio<Export>', where <Export> is the export number for the
%   line, which is calculated by adding the Offset to the Base number of
%   the Chip. If the symbolic link exists, then the GPIO line is
%   exported. If the symbolic link does not exist, then the GPIO line is
%   not exported.
%
%   @arg Chip is the name of the GPIO chip, such as gpiochip0, gpiochip1, etc.
%   @arg Offset is the offset of the GPIO line within the chip. This is
%   a number that is added to the base number of the chip to calculate
%   the export number for the line.
%   @arg Export is the export number for the GPIO line, which is
%   calculated by adding the Offset to the Base number of the Chip. This
%   is the number that is written to the export pseudo-file in the gpio
%   class of sysfs to export the line, and is also used in the name of
%   the symbolic link that is created in the gpio class of sysfs when
%   the line is exported.
%   @arg Line is the name of the GPIO line, which is constructed as
%   'gpio<Export>', where <Export> is the Export number for the line.
%   This is the name of the symbolic link that is created in the gpio
%   class of sysfs when the line is exported, and can be used to access
%   the line in the sysfs virtual file system.

sysfs_gpio_exported(Chip, Offset, Export, Line) :-
    sysfs_gpio_line(Chip, Offset, Export, Line),
    % Exporting creates a symbolic link in the gpio class of sysfs with
    % the name gpio<Export>. If the symbolic link exists, then the GPIO
    % line is exported. If the symbolic link does not exist, then
    % the GPIO line is not exported.
    %
    % At the version 9.x.x of SWI-Prolog, the following does not work on
    % symbolic links:
    %
    %   absolute_file_name(sysfs_class_gpio(Line), _, [file_errors(fail), access(search)]).
    %
    absolute_file_name(sysfs_class_gpio(Line), Abs),
    access_file(Abs, search).

%!  sysfs_gpio_ensure_exported(?Chip, ?Offset, -Export, -Line) is nondet.
%
%   Ensures that a GPIO line is exported by checking if it is already
%   exported, and if not, then exporting it. The predicate is
%   nondeterministic and can be backtracked to find all lines for a
%   given Chip and Offset, or to find the Chip and Offset for a given
%   Export and Line.
%
%   @arg Chip is the name of the GPIO chip, such as gpiochip0, gpiochip1, etc.
%   @arg Offset is the offset of the GPIO line within the chip. This is
%   a number that is added to the base number of the chip to calculate
%   the export number for the line.
%   @arg Export is the export number for the GPIO line, which is
%   calculated by adding the Offset to the Base number of the Chip. This
%   is the number that is written to the export pseudo-file in the gpio
%   class of sysfs to export the line, and is also used in the name of
%   the symbolic link that is created in the gpio class of sysfs when
%   the line is exported.
%   @arg Line is the name of the GPIO line, which is constructed as
%   'gpio<Export>', where <Export> is the Export number for the line.
%   This is the name of the symbolic link that is created in the gpio
%   class of sysfs when the line is exported, and can be used to access
%   the line in the sysfs virtual file system.

sysfs_gpio_ensure_exported(Chip, Offset, Export, Line) :-
    sysfs_gpio_line(Chip, Offset, Export, Line),
    (   sysfs_gpio_exported(Chip, Offset, Export, Line)
    ->  true
    ;   sysfs_gpio_export(Chip, Offset, Export, Line)
    ).

%!  sysfs_gpio_ensure_unexported(?Chip, ?Offset, -Export, -Line) is nondet.
%
%   Ensures that a GPIO line is unexported by checking if it is already
%   unexported, and if not, then unexporting it. The predicate is
%   nondeterministic and can be backtracked to find all lines for a
%   given Chip and Offset, or to find the Chip and Offset for a given
%   Export and Line.
%
%   @arg Chip is the name of the GPIO chip, such as gpiochip0, gpiochip1, etc.
%
%   @arg Offset is the offset of the GPIO line within the chip. This is
%   a number that is added to the base number of the chip to calculate
%   the export number for the line.
%
%   @arg Export is the export number for the GPIO line, which is
%   calculated by adding the Offset to the Base number of the Chip. This
%   is the number that is written to the unexport pseudo-file in the
%   gpio class of sysfs to unexport the line, and is also used in the
%   name of the symbolic link that is created in the gpio class of sysfs
%   when the line is exported.
%
%   @arg Line is the name of the GPIO line, which is constructed as
%   'gpio<Export>', where <Export> is the Export number for the line.
%   This is the name of the symbolic link that is created in the gpio
%   class of sysfs when the line is exported, and can be used to access
%   the line in the sysfs virtual file system.

sysfs_gpio_ensure_unexported(Chip, Offset, Export, Line) :-
    sysfs_gpio_line(Chip, Offset, Export, Line),
    (   sysfs_gpio_exported(Chip, Offset, Export, Line)
    ->  sysfs_gpio_unexport(Chip, Offset, Export, Line)
    ;   true
    ).

%!  sysfs_gpio_read(?File, ?Chip, ?Offset, -Data) is nondet.
%!  sysfs_gpio_read(?File, ?Line, -Data) is nondet.
%
%   Reads a value from a file in the GPIO line directory in sysfs. The
%   File is the name of the file to read, such as value, direction, etc.
%   The Chip is the name of the GPIO chip, such as gpiochip0, gpiochip1,
%   etc. The Offset is the offset of the GPIO line within the chip. The
%   Line is the name of the GPIO line, which is constructed as
%   'gpio<Export>', where <Export> is the export number for the line.
%   The Data is the value read from the file. The predicate is
%   nondeterministic and can be backtracked to find all lines for a
%   given Chip and Offset, or to find the Chip and Offset for a given
%   Line.
%
%   @arg File is the name of the file to read, such as value, direction, etc.
%
%   @arg Chip is the name of the GPIO chip, such as gpiochip0, gpiochip1, etc.
%
%   @arg Offset is the offset of the GPIO line within the chip. This is
%   a number that is added to the base number of the chip to calculate
%   the export number for the line.
%
%   @arg Line is the name of the GPIO line, which is constructed as
%   'gpio<Export>', where <Export> is the export number for the line.
%   This is the name of the symbolic link that is created in the gpio
%   class of sysfs when the line is exported, and can be used to access
%   the line in the sysfs virtual file system.
%
%   @arg Data is the value read from the file.

sysfs_gpio_read(File, Chip, Offset, Data) :-
    file_as(File, As),
    sysfs_gpio_ensure_exported(Chip, Offset, _, Line),
    sysfs_exported_with_time_limit(sysfs_class_gpio(Line/File), Abs, [access(read)]),
    read_file_as(As, Abs, Data).

sysfs_gpio_read(File, Line, Data) :-
    file_as(File, As),
    sysfs_gpio_exported(_, _, _, Line),
    read_file_as(As, sysfs_class_gpio(Line/File), Data).

%!  sysfs_gpio_write(?File, ?Chip, ?Offset, +Data) is nondet.
%!  sysfs_gpio_write(?File, ?Line, +Data) is nondet.
%
%   Writes a value to a file in the GPIO line directory in sysfs. The
%   File is the name of the file to write, such as value, direction,
%   etc. The Chip is the name of the GPIO chip, such as gpiochip0,
%   gpiochip1, etc. The Offset is the offset of the GPIO line within the
%   chip. The Line is the name of the GPIO line, which is constructed as
%   'gpio<Export>', where <Export> is the export number for the line.
%   The Data is the value to write to the file. The predicate is
%   nondeterministic and can be backtracked to find all lines for a
%   given Chip and Offset, or to find the Chip and Offset for a given
%   Line.
%
%   @arg File is the name of the file to write, such as value, direction, etc.
%
%   @arg Chip is the name of the GPIO chip, such as gpiochip0, gpiochip1, etc.
%
%   @arg Offset is the offset of the GPIO line within the chip. This is
%   a number that is added to the base number of the chip to calculate
%   the export number for the line.
%
%   @arg Line is the name of the GPIO line, which is constructed as
%   'gpio<Export>', where <Export> is the export number for the line.
%   This is the name of the symbolic link that is created in the gpio
%   class of sysfs when the line is exported, and can be used to access
%   the line in the sysfs virtual file system.
%
%   @arg Data is the value to write to the file.

sysfs_gpio_write(File, Chip, Offset, Data) :-
    file_as(File, As),
    sysfs_gpio_ensure_exported(Chip, Offset, _, Line),
    sysfs_exported_with_time_limit(sysfs_class_gpio(Line/File), Abs, [access(write)]),
    write_file_as(As, Abs, Data).

sysfs_gpio_write(File, Line, Data) :-
    file_as(File, As),
    sysfs_gpio_exported(_, _, _, Line),
    write_file_as(As, sysfs_class_gpio(Line/File), Data).

file_as(value, number).
file_as(active_low, number).
file_as(direction, atom).
file_as(edge, atom).

%!  sysfs_gpio_line(?Chip, ?Offset, -Export, -Line) is nondet.
%
%   Finds the Export number and Line name for a given Chip and Offset. The
%   Export number is calculated by adding the Offset to the Base number of the
%   Chip, which is read from the base file in the Chip directory in the gpio
%   class of sysfs. The Line name is then constructed as 'gpio<Export>', where
%   <Export> is the Export number. The predicate is nondeterministic and can be
%   backtracked to find all lines for a given Chip, or to find the Chip and
%   Offset for a given Export and Line.
%
%   @arg Chip is the name of a GPIO chip, which is a directory in the gpio class
%   of sysfs that contains a file named base, which specifies the base number
%   for the chip.
%
%   @arg Offset is the offset of the GPIO line within the chip. This is a number
%   that is added to the base number of the chip to calculate the export number
%   for the line.
%
%   @arg Export is the export number for the GPIO line, which is calculated by
%   adding the Offset to the Base number of the Chip. This is the number that is
%   written to the export pseudo-file in the gpio class of sysfs to export the
%   line, and is also used in the name of the symbolic link that is created in
%   the gpio class of sysfs when the line is exported.
%
%   @arg Line is the name of the GPIO line, which is constructed as
%   'gpio<Export>', where <Export> is the Export number for the line. This is
%   the name of the symbolic link that is created in the gpio class of sysfs
%   when the line is exported, and can be used to access the line in the sysfs
%   virtual file system.

sysfs_gpio_line(Chip, Offset, Export, Line) :-
    sysfs_gpiochip_read(ngpio, Chip, N),
    sysfs_gpiochip_read(base, Chip, Base),
    % Read the base address and number of lines (ngpio) for the chip
    % upfront, before backtracking on the offset, to avoid reading the
    % base and ngpio files multiple times when backtracking on the
    % offset. This is an optimisation to reduce the number of file
    % reads, as the base and ngpio values are the same for all lines in
    % the chip, and only need to be read once per chip.
    succ(N0, N),
    between(0, N0, Offset),
    plus(Base, Offset, Export),
    format(atom(Line), 'gpio~d', [Export]).

:- multifile user:file_search_path/2.

user:file_search_path(sysfs_class_gpio, sysfs_class(gpio)).
