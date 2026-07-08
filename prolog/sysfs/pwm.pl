/*  File:    sysfs/pwm.pl
    Author:  Roy Ratcliffe
    Created: Dec 10 2024
    Purpose: Linux sysfs PWM Access

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

:- module(sysfs_pwm,
          [ sysfs_pwm_export/3, % +Chip, ?Export, -Chan
            sysfs_pwm_unexport/3, % +Chip, ?Export, -Chan
            sysfs_pwm_exported/3, % ?Chip, ?Export, -Chan
            sysfs_pwm_ensure_exported/3, % ?Chip, ?Export, -Chan
            sysfs_pwm_ensure_unexported/3, % ?Chip, ?Export, -Chan
            sysfs_pwm_read/4, % +File, +Chip, ?Export, -Data
            sysfs_pwm_write/4, % +File, +Chip, ?Export, +Data
            sysfs_pwm_chan/3 % ?Chip, ?Export, -Chan
          ]).
:- use_module(library(sysfs)).
:- use_module(pwmchip).
:- use_module(read_file).
:- use_module(write_file).

%!  sysfs_pwm_export(+Chip, ?Export, -Chan) is nondet.
%
%   Exports a PWM channel by writing its number to the export file of the Chip.
%   The Export is a number that identifies the PWM channel, and the Chan is the
%   name of the file in the sysfs virtual file system that corresponds to the
%   exported PWM channel, which is of the form pwmN, where N is the number of
%   the PWM channel. The predicate is nondeterministic and can be backtracked to
%   export multiple PWM channels for the specified Chip.
%
%   @arg Chip is the name of a PWM class device, which is a directory in the
%   /sys/class/pwm directory that contains a file named `npwm`.
%
%   @arg Export is the number that identifies the exported PWM channel. This is
%   an integer.
%
%   @arg Chan is the "name of the file" in the sysfs virtual file system that
%   corresponds to the exported PWM channel. This is returned as an atom. The
%   name _excludes_ the directory path, and is of the form pwmN, where N is the
%   number of the PWM channel.

sysfs_pwm_export(Chip, Export, Chan) :-
    sysfs_pwm_chan(Chip, Export, Chan),
    write_file_as(sysfs_class_pwm(Chip/export), number(Export)).

%!  sysfs_pwm_unexport(+Chip, ?Export, -Chan) is nondet.
%
%   Unexports a PWM channel by writing its number to the unexport file of the
%   Chip. The Export is a number that identifies the PWM channel, and the Chan
%   is the name of the file in the sysfs virtual file system that corresponds to
%   the exported PWM channel, which is of the form pwmN, where N is the number
%   of the PWM channel. The predicate is nondeterministic and can be backtracked
%   to unexport multiple PWM channels for the specified Chip.
%
%   @arg Chip is the name of a PWM class device, which is a directory in the
%   /sys/class/pwm directory that contains a file named `npwm`.
%
%   @arg Export is the number that identifies the exported PWM channel. This is
%   an integer.
%
%   @arg Chan is the "name of the file" in the sysfs virtual file system that
%   corresponds to the exported PWM channel. This is returned as an atom. The
%   name _excludes_ the directory path, and is of the form pwmN, where N is the
%   number of the PWM channel.

sysfs_pwm_unexport(Chip, Export, Chan) :-
    sysfs_pwm_chan(Chip, Export, Chan),
    write_file_as(sysfs_class_pwm(Chip/unexport), number(Export)).

%!  sysfs_pwm_exported(?Chip, ?Export, -Chan) is nondet.
%
%   Finds an Export that is a PWM channel exported by the specified
%   Chip, and returns the corresponding PWM. A PWM channel is exported
%   by writing its number to the export file of the Chip, which is a
%   file named export in the directory of the Chip in the sysfs virtual
%   file system.
%
%   @arg Chip is the name of a PWM class device, which is a directory in
%   the /sys/class/pwm directory that contains a file named `npwm`.
%
%   @arg Export is the number that identifies the exported PWM channel.
%   This is an integer.
%
%   @arg Chan is the "name of the file" in the sysfs virtual file system that
%   corresponds to the exported PWM channel. This is returned as an atom.

sysfs_pwm_exported(Chip, Export, Chan) :-
    sysfs_pwmchip_path(Chip, Path),
    sysfs_pwm_chan(Chip, Export, Chan),
    absolute_file_name(Path/Chan, Abs),
    access_file(Abs, search).

%!  sysfs_pwm_ensure_exported(?Chip, ?Export, -Chan) is nondet.
%
%   Ensures that a PWM channel is exported by the specified Chip.
%   If already exported, succeeds. Otherwise, exports the channel.
%
%   @arg Chip PWM class device name (directory in /sys/class/pwm with `npwm`).
%   @arg Export integer identifying the PWM channel.
%   @arg Chan atom of the form pwmN where N is the channel number.

sysfs_pwm_ensure_exported(Chip, Export, Chan) :-
    sysfs_pwm_chan(Chip, Export, Chan),
    (   sysfs_pwm_exported(Chip, Export, Chan)
    ->  true
    ;   sysfs_pwm_export(Chip, Export, Chan)
    ).

%!  sysfs_pwm_ensure_unexported(?Chip, ?Export, -Chan) is nondet.
%
%   Ensures that a PWM channel is unexported by the specified Chip.
%   If already unexported, succeeds. Otherwise, unexports the channel.
%
%   @arg Chip PWM class device name (directory in /sys/class/pwm with `npwm`).
%
%   @arg Export integer identifying the PWM channel.
%
%   @arg Chan atom of the form pwmN where N is the channel number.

sysfs_pwm_ensure_unexported(Chip, Export, Chan) :-
    sysfs_pwm_chan(Chip, Export, Chan),
    (   sysfs_pwm_exported(Chip, Export, Chan)
    ->  sysfs_pwm_unexport(Chip, Export, Chan)
    ;   true
    ).

%!  sysfs_pwm_read(?File, ?Chip, ?Export, -Data) is nondet.
%
%   Reads a value from a file in the directory of a PWM channel. The File is the
%   name of the file to read, such as enable, period, duty_cycle, polarity, etc.
%   The Chip is the name of the PWM class device, such as pwmchip0, pwmchip1,
%   etc. The Export is the number that identifies the exported PWM channel. The
%   Data is the value read from the file, and is returned as an atom or a number
%   depending on the type of the file. The predicate is nondeterministic and can
%   be backtracked to read the values of multiple files in the directory of a
%   PWM channel, or to read the values of the same file in multiple PWM
%   channels.
%
%   Automatically ensures that the specified PWM channel is exported before
%   reading the file. If the channel is not already exported, it will be
%   exported by this predicate. This allows the caller to read files from a PWM
%   channel without having to manually export the channel first, and ensures
%   that the channel is exported when needed.
%
%   @arg File is the name of the file to read, such as enable, period, duty_cycle,
%   polarity, etc.
%
%   @arg Chip is the name of the PWM class device, such as pwmchip0, pwmchip1, etc.
%
%   @arg Export is the number that identifies the exported PWM channel.
%
%   @arg Data is the value read from the file, and is returned as an atom or a
%   number depending on the type of the file.

sysfs_pwm_read(File, Chip, Export, Data) :-
    file_as(File, As),
    sysfs_pwm_ensure_exported(Chip, Export, Chan),
    sysfs_exported_with_time_limit(sysfs_class_pwm(Chip/Chan/File), Abs, [access(read)]),
    read_file_as(As, Abs, Data).

%!  sysfs_pwm_write(File, +Chip, +Export, +Data) is nondet.
%
%   Writes a value to a file in the directory of a PWM channel. The File is the
%   name of the file to write, such as enable, period, duty_cycle, polarity,
%   etc. The Chip is the name of the PWM class device, such as pwmchip0,
%   pwmchip1, etc. The Export is the number that identifies the exported PWM
%   channel. The Data is the value to write to the file, and is expected to be
%   an atom or a number depending on the type of the file. The predicate is
%   nondeterministic and can be backtracked to write values to multiple files in
%   the directory of a PWM channel, or to write values to the same file in
%   multiple PWM channels.
%
%   Automatically ensures that the specified PWM channel is exported before
%   writing to the file. If the channel is not already exported, it will be
%   exported by this predicate. This allows the caller to write to files in a
%   PWM channel without having to manually export the channel first, and ensures
%   that the channel is exported when needed.
%
%   @arg File is the name of the file to write, such as enable, period,
%   duty_cycle, polarity, etc.
%
%   @arg Chip is the name of the PWM class device, such as pwmchip0, pwmchip1, etc.
%
%   @arg Export is the number that identifies the exported PWM channel.
%
%   @arg Data is the value to write to the file, and is expected to be an atom
%   or a number depending on the type of the file. The value will be written to
%   the file as a string, so if Data is a number, it will be converted to a
%   string before writing, and if Data is an atom, it will also be converted to
%   a string before writing. The value will be written to the file in the sysfs
%   virtual file system, which is typically of the form
%   /sys/class/pwm/pwmchipN/pwmM/File, where N is the number of the Chip, M is
%   the number of the exported PWM channel, and File is the name of the file to
%   write. The predicate will succeed if the value is successfully written to
%   the file, and will fail if there is an error writing to the file, such as if
%   the file does not exist, if the channel is not exported and cannot be
%   exported, if the value cannot be converted to a string, or if there is a
%   permission error when writing to the file. The predicate is nondeterministic
%   and can be backtracked to write values to multiple files in the directory of
%   a PWM channel, or to write values to the same file in multiple PWM channels.

sysfs_pwm_write(File, Chip, Export, Data) :-
    file_as(File, As),
    sysfs_pwm_ensure_exported(Chip, Export, Chan),
    sysfs_exported_with_time_limit(sysfs_class_pwm(Chip/Chan/File), Abs, [access(write)]),
    write_file_as(As, Abs, Data).

file_as(enable, number).
file_as(period, number).
file_as(duty_cycle, number).
file_as(polarity, atom).

%!  sysfs_pwm_chan(?Chip, ?Export, -Chan) is nondet.
%
%   Finds an Export that is a PWM channel exported by the specified
%   Chip, and returns the corresponding Chan. A PWM channel is exported
%   by writing its number to the export file of the Chip, which is a
%   file named export in the directory of the Chip in the sysfs virtual
%   file system. The Export is a number that identifies the PWM channel,
%   and the Chan is the name of the file in the sysfs virtual file
%   system that corresponds to the exported PWM channel, which is of the
%   form pwmN, where N is the number of the PWM channel.
%
%   @arg Chip is the name of a PWM class device, which is a directory in
%   the /sys/class/pwm directory that contains a file named `npwm`.
%
%   @arg Export is the number that identifies the exported PWM channel.
%   This is an integer.
%
%   @arg Chan is the "name of the file" in the sysfs virtual file system
%   that corresponds to the exported PWM channel. This is returned as an
%   atom. The name _excludes_ the directory path, and is of the form pwmN,
%   where N is the number of the PWM channel.

sysfs_pwm_chan(Chip, Export, Chan) :-
    sysfs_pwmchip_read(npwm, Chip, N),
    succ(N0, N),
    between(0, N0, Export),
    format(atom(Chan), 'pwm~d', [Export]).

:- multifile user:file_search_path/2.

% Define file search paths for sysfs classes. These allow us to refer to files
% in the sysfs virtual file system using relative paths that are more convenient
% and readable.
user:file_search_path(sysfs_class_pwm, sysfs_class(pwm)).
