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
          [ sysfs_pwm_export/3 % +Chip, ?Export, -Chan
          , sysfs_pwm_unexport/3 % +Chip, ?Export, -Chan
          , sysfs_pwm_exported/3 % ?Chip, ?Export, -Chan
          , sysfs_pwm_ensure_exported/3 % ?Chip, ?Export, -Chan
          , sysfs_pwm_ensure_unexported/3 % ?Chip, ?Export, -Chan
          , sysfs_pwm_read/4 % +File, +Chip, ?Export, -Data
          , sysfs_pwm_write/4 % +File, +Chip, ?Export, +Data
          , sysfs_pwm_chan/3 % ?Chip, ?Export, -Chan
          , sysfs_pwm_read/3 % ?Chip, ?Export, +Term
          , sysfs_pwm_write/3 % ?Chip, ?Export, ++Term
          , sysfs_pwm/3 % ?Chip, ?Export, ?PWM
          , sysfs_pwm/1 % ?PWM
          , sysfs_pwm_ensure_exported/1 % ?PWM
          , sysfs_pwm_read/2 % ?PWM, +Term
          , sysfs_pwm_write/2 % ?PWM, ++Term
          ]).
:- use_module(library(sysfs)).
:- use_module(library(sysfs/pwmchip)).
:- use_module(library(sysfs/read_file)).
:- use_module(library(sysfs/write_file)).

/** <module> Linux sysfs PWM Access
 *
 * This module provides predicates to access PWM class devices in the Linux
 * sysfs virtual file system. PWM class devices are represented as directories
 * in the /sys/class/pwm directory, and contain files that provide information
 * about the device and its capabilities. The predicates in this module allow
 * you to export and unexport PWM channels, read and write values to files in
 * the directories of PWM channels, and find the paths to PWM class devices.
 *
 * The main predicates in this module are:
 *
 * - sysfs_pwm_export/3 exports a PWM channel by writing its number to the
 *   export file of the Chip.
 * - sysfs_pwm_unexport/3 unexports a PWM channel by writing its number to the
 *   unexport file of the Chip.
 * - sysfs_pwm_exported/3 finds an Export that is a PWM channel exported by the
 *   specified Chip, and returns the corresponding Chan.
 * - sysfs_pwm_ensure_exported/3 ensures that a PWM channel is exported by the
 *   specified Chip.
 * - sysfs_pwm_ensure_unexported/3 ensures that a PWM channel is unexported by
 *   the specified Chip.
 * - sysfs_pwm_read/3 reads a value from a file in the directory of a PWM
 *   channel, given a term that specifies the device and file, and the type of
 *   value to read.
 * - sysfs_pwm_read/4 reads a value from a file in the directory of a PWM
 *   channel, given the file name, device name, and returns the value read from
 *   the file.
 * - sysfs_pwm_write/3 writes a value to a file in the directory of a PWM
 *   channel, given a term that specifies the device and file, and the value to
 *   write.
 * - sysfs_pwm_write/4 writes a value to a file in the directory of a PWM
 *   channel, given the file name, device name, and value to write.
 *
 * The predicates in this module are designed to be flexible and can be used in
 * various ways to access PWM class devices and their files in the sysfs virtual
 * file system.
 *
 * ---+++ Example Usage
 *
 * To export a PWM channel:
 *
 * ?- sysfs_pwm_export(pwmchip0, 0, Chan).
 *
 * To unexport a PWM channel:
 *
 * ?- sysfs_pwm_unexport(pwmchip0, 0, Chan).
 *
 * To read the period of a PWM channel:
 *
 * ?- sysfs_pwm_read(pwmchip0, 0, period(NS, ns)).
 *
 * To write the duty cycle of a PWM channel:
 *
 * ?- sysfs_pwm_write(pwmchip0, 0, duty_cycle(50, percent)).
 *
 * To find the path to a specific PWM class device:
 *
 * ?- sysfs_pwmchip_path(pwmchip0, Path).
 *
 * To find all PWM class devices and their paths:
 *
 * ?- sysfs_pwmchip_path(Chip, Path).
 *
 * ---+++ Two Arity
 *
 * The predicates sysfs_pwm/3, sysfs_pwm/1, sysfs_pwm_read/2, and sysfs_pwm_write/2 provide a more convenient interface for accessing PWM channels by using a compound term to represent the device and channel. For example:
 *
 * ?- sysfs_pwm(pwmchip0, 0, PWM), sysfs_pwm_read(PWM, period(NS, ns)).
 *
 * The PWM is a
 * compound term of the form Chip(Chan), where  Chan is the name of the
 * file in the sysfs  virtual  file   system  that  corresponds  to the
 * exported PWM channel, which is of  the   form  pwmN,  where N is the
 * number of the PWM channel. The Term's   arguments  are the values to
 * write to the  corresponding  files  in   the  directory  of  the PWM
 * channel. The first argument is the value   to write to the file; the
 * second argument, if present, specifies the  unit of the value (e.g.,
 * ns, s, hz, percent, fract). The   predicate  is nondeterministic and
 * can be backtracked to write the  values   to  multiple  files in the
 * directory of a PWM channel, or to write  the values to the same file
 * in multiple PWM channels. The   predicate automatically ensures that
 * the specified PWM channel is exported   before writing to the files.
 * If the channel is not already exported,  it will be exported by this
 * predicate. This allows the caller to write to files in a PWM channel
 * without having to manually export  the   channel  first, and ensures
 * that the channel is exported when needed.
 *
 * @author Roy Ratcliffe
 * @version 1.0
 * @license MIT
 */

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

                /*******************************
                *         THREE ARITY          *
                *******************************/

%!  sysfs_pwm_read(?Chip, ?Export, +Term) is nondet.
%
%   Reads a value from a file in  the   directory  of a PWM channel. The
%   Term is a Prolog term that  specifies  the   file  to  read. It is a
%   compound term with the name of the file  as the functor. The Chip is
%   the name of the PWM class device,   such as pwmchip0, pwmchip1, etc.
%   The Export is the number that   identifies the exported PWM channel.
%   The Term's arguments are  unified  with   the  values  read from the
%   corresponding files in the directory of   the PWM channel. The first
%   argument unifies with the  value  read   from  the  file; the second
%   argument, if present, specifies the unit of  the value (e.g., ns, s,
%   hz, percent, fract). The predicate is   nondeterministic  and can be
%   backtracked to read the values of multiple files in the directory of
%   a PWM channel, or to read the values   of  the same file in multiple
%   PWM channels.
%
%   Automatically ensures that the  specified   PWM  channel is exported
%   before reading the file. If the channel  is not already exported, it
%   will be exported by this predicate. This   allows the caller to read
%   files from a PWM  channel  without   having  to  manually export the
%   channel first, and ensures that the channel is exported when needed.
%
%   @arg Chip is the name of the PWM class device, such as pwmchip0,
%   pwmchip1, etc.
%
%   @arg Export is the number that identifies the exported PWM channel.
%
%   @arg Term is a Prolog term that specifies the file to read, with the
%   name of the file as the functor and  the value read from the file as
%   the first argument. The second argument,  if any, specifies the unit
%   of the value (e.g., ns, s, hz, percent, fract).

sysfs_pwm_read(Chip, Export, Term) :- read_pwm(Term, Chip, Export).

read_pwm(enable(Enable), Chip, Export) :-
    sysfs_pwm_read(enable, Chip, Export, Enable).
read_pwm(polarity(Polarity), Chip, Export) :-
    sysfs_pwm_read(polarity, Chip, Export, Polarity).
read_pwm(period(NS, ns), Chip, Export) :-
    sysfs_pwm_read(period, Chip, Export, NS).
read_pwm(period(S, s), Chip, Export) :-
    read_pwm(period(NS, ns), Chip, Export),
    s(NS, S).
read_pwm(period(Hz, hz), Chip, Export) :-
    read_pwm(period(NS, ns), Chip, Export),
    hz(NS, Hz).
read_pwm(duty_cycle(NS, ns), Chip, Export) :-
    sysfs_pwm_read(duty_cycle, Chip, Export, NS).
read_pwm(duty_cycle(S, s), Chip, Export) :-
    read_pwm(duty_cycle(NS, ns), Chip, Export),
    s(NS, S).
read_pwm(duty_cycle(Hz, hz), Chip, Export) :-
    read_pwm(duty_cycle(NS, ns), Chip, Export),
    hz(NS, Hz).
read_pwm(duty_cycle(Fract, fract), Chip, Export) :-
    read_pwm(period(Period, ns), Chip, Export),
    read_pwm(duty_cycle(DutyCycle, ns), Chip, Export),
    Fract is DutyCycle / Period.
read_pwm(duty_cycle(Percent, percent), Chip, Export) :-
    read_pwm(duty_cycle(Fract, fract), Chip, Export),
    Percent is 100 * Fract.

%!  sysfs_pwm_write(+Chip, +Export, ++Term) is det.
%
%   Writes a value to a file in the directory of a PWM channel. The Term
%   is a Prolog term that specifies the file  to write. It is a compound
%   term with the name of the file as  the functor. The Chip is the name
%   of the PWM class device, such as pwmchip0, pwmchip1, etc. The Export
%   is the number that identifies the   exported PWM channel. The Term's
%   arguments are the values to write to  the corresponding files in the
%   directory of the PWM channel. The  first   argument  is the value to
%   write to the file; the second   argument,  if present, specifies the
%   unit of the value (e.g., ns, s,   hz, percent, fract). The predicate
%   is deterministic and will succeed  if   the  values are successfully
%   written to the files, and will fail if  there is an error writing to
%   any of the files, such as if a   file does not exist, if the channel
%   is not exported and  cannot  be  exported,   if  a  value  cannot be
%   converted to a string, or  if  there   is  a  permission  error when
%   writing to a file. The  predicate   automatically  ensures  that the
%   specified PWM channel is exported before   writing  to the files. If
%   the channel is not already exported,  it   will  be exported by this
%   predicate. This allows the caller to write to files in a PWM channel
%   without having to manually export  the   channel  first, and ensures
%   that the channel is exported when needed.
%
%   @arg Chip is the name of the PWM class device, such as pwmchip0,
%   pwmchip1, etc.
%
%   @arg Export is the number that identifies the exported PWM channel.
%
%   @arg Term is a Prolog term that   specifies  the file to write, with
%   the name of the file as the functor   and  the value to write to the
%   file as the first argument. The   second argument, if any, specifies
%   the unit of the value (e.g., ns, s, hz, percent, fract).

sysfs_pwm_write(Chip, Export, Term) :- write_pwm(Term, Chip, Export).

write_pwm(enable(Enable), Chip, Export) :-
    sysfs_pwm_write(enable, Chip, Export, Enable).
write_pwm(polarity(Polarity), Chip, Export) :-
    sysfs_pwm_write(polarity, Chip, Export, Polarity).
write_pwm(period(NS, ns), Chip, Export) :-
    NS_ is round(NS),
    sysfs_pwm_write(period, Chip, Export, NS_).
write_pwm(period(S, s), Chip, Export) :-
    s(NS, S),
    write_pwm(period(NS, ns), Chip, Export).
write_pwm(period(Hz, hz), Chip, Export) :-
    hz(NS, Hz),
    write_pwm(period(NS, ns), Chip, Export).
write_pwm(duty_cycle(NS, ns), Chip, Export) :-
    NS_ is round(NS),
    sysfs_pwm_write(duty_cycle, Chip, Export, NS_).
write_pwm(duty_cycle(S, s), Chip, Export) :-
    s(NS, S),
    write_pwm(duty_cycle(NS, ns), Chip, Export).
write_pwm(duty_cycle(Hz, hz), Chip, Export) :-
    hz(NS, Hz),
    write_pwm(duty_cycle(NS, ns), Chip, Export).
write_pwm(duty_cycle(Fract, fract), Chip, Export) :-
    read_pwm(period(Period, ns), Chip, Export),
    DutyCycle is Fract * Period,
    write_pwm(duty_cycle(DutyCycle, ns), Chip, Export).
write_pwm(duty_cycle(Percent, percent), Chip, Export) :-
    Fract is Percent / 100,
    write_pwm(duty_cycle(Fract, fract), Chip, Export).

%!  s(NS, S) is det.
%
%   Converts between nanoseconds and  seconds.  NS   is  the  number  of
%   nanoseconds, and S is the number of seconds. If NS is a variable, it
%   will be unified with the number   of  nanoseconds corresponding to S
%   seconds. If S is a variable, it will   be unified with the number of
%   seconds  corresponding  to  NS   nanoseconds.    The   predicate  is
%   deterministic and will succeed if the  conversion is successful, and
%   fail otherwise.
%
%   @arg NS is the number of nanoseconds, which is a float.
%   @arg S is the number of seconds, which is a float.

s(NS, S), var(NS) => NS is 1_000_000_000 * S.
s(NS, S) => S is NS / 1_000_000_000.

%!  hz(NS, Hz) is det.
%
%   Converts  between  nanoseconds  and  Hertz.  NS  is  the  number  of
%   nanoseconds, and Hz is the frequency in  Hertz. If NS is a variable,
%   it will be unified with the   number of nanoseconds corresponding to
%   Hz Hertz. If Hz is a variable, it will be unified with the frequency
%   in  Hertz  corresponding  to  NS    nanoseconds.  The  predicate  is
%   deterministic and will succeed if the  conversion is successful, and
%   fail otherwise.
%
%   @arg NS is the number of nanoseconds, which is a float.
%   @arg Hz is the frequency in Hertz, which is a float.

hz(NS, Hz), var(NS) => NS is 1_000_000_000 / Hz.
hz(NS, Hz) => NS > 0, Hz is 1_000_000_000 / NS.

                /*******************************
                *          TWO ARITY           *
                *******************************/

%!  sysfs_pwm(?Chip, ?Export, ?PWM) is nondet.
%!  sysfs_pwm(?PWM) is nondet.
%
%   Within sysfs, a PWM channel  is   represented  as  a directory named
%   pwmN, where N is the number of   the channel. The directory contains
%   files  that  provide  information   about    the   channel  and  its
%   capabilities, such as enable, period,  duty_cycle, and polarity. The
%   pwmN directory appears within the  chip   directory,  which is named
%   pwmchipN, where N is the number of the   chip.  Hence, the path to a
%   PWM   channel   in    sysfs    is     typically    of    the    form
%   /sys/class/pwm/pwmchipN/pwmM, where N is the number  of the chip and
%   M is the number of  the  channel.   Consequently,  a  PWM channel is
%   uniquely identified by the  combination  of   its  chip  and channel
%   numbers.
%
%   @arg Chip is the name of a PWM class device, which is a directory in
%   the /sys/class/pwm directory that contains a file named `npwm`.
%
%   @arg Export is the number that identifies the exported PWM channel.
%
%   @arg PWM is a compound term of the form Chip(Chan), where Chan is the
%   name of the file in the sysfs virtual file system that corresponds to
%   the exported PWM channel, which is of the form pwmN, where N is the
%   number of the PWM channel. The term uniquely identifies a PWM channel
%   in sysfs by combining the chip and channel numbers.

sysfs_pwm(Chip, Export, PWM) :-
    sysfs_pwm_chan(Chip, Export, Chan),
    PWM =.. [Chip, Chan].

sysfs_pwm(PWM) :- sysfs_pwm(_, _, PWM).

%!  sysfs_pwm_ensure_exported(?PWM) is nondet.
%
%   Ensures that a PWM channel is exported by the implied chip.
%   If already exported, succeeds. Otherwise, exports the channel.
%
%   @arg PWM is a compound term of the form Chip(Chan), where Chan is
%   the name of the file in the sysfs virtual file system that corresponds
%   to the exported PWM channel, which is of the form pwmN, where N is
%   the number of the PWM channel.

sysfs_pwm_ensure_exported(PWM) :-
    % First derive the Chip and Export from the PWM term, then ensure that the channel is exported.
    % Throw away the Chan since it is not needed for the ensure-export operation.
    sysfs_pwm(Chip, Export, PWM),
    sysfs_pwm_ensure_exported(Chip, Export, _).

%!  sysfs_pwm_read(?PWM, +Term) is nondet.
%
%   Reads a value from a file in  the   directory  of a PWM channel. The
%   Term is a Prolog term that  specifies  the   file  to  read. It is a
%   compound term with the name of the file as the functor. The PWM is a
%   compound term of the form Chip(Chan), where  Chan is the name of the
%   file in the sysfs  virtual  file   system  that  corresponds  to the
%   exported PWM channel, which is of  the   form  pwmN,  where N is the
%   number of the PWM channel. The Term's arguments are unified with the
%   values read from the corresponding files in the directory of the PWM
%   channel. The first argument unifies  with   the  value read from the
%   file; the second argument, if  present,   specifies  the unit of the
%   value  (e.g.,  ns,  s,  hz,  percent,    fract).  The  predicate  is
%   nondeterministic and can be  backtracked  to   read  the  values  of
%   multiple files in the directory of  a   PWM  channel, or to read the
%   values of the same file in multiple PWM channels.
%
%   @arg PWM is a compound term of   the  form Chip(Chan), where Chan is
%   the name of  the  file  in  the   sysfs  virtual  file  system  that
%   corresponds to the exported PWM channel, which  is of the form pwmN,
%   where N is the number of the PWM channel.
%
%   @arg Term is a Prolog term that specifies the file to read, with the
%   name of the file as the functor and  the value read from the file as
%   the first argument. The second argument,  if any, specifies the unit
%   of the value (e.g., ns, s, hz, percent, fract).

sysfs_pwm_read(PWM, Term) :-
    sysfs_pwm(Chip, Export, PWM),
    sysfs_pwm_read(Chip, Export, Term).

%!  sysfs_pwm_write(?PWM, ++Term) is nondet.
%
%   Writes a value to a file in the directory of a PWM channel.
%
%   The Term is a Prolog term that specifies  the file to write. It is a
%   compound term with the name of the file as the functor; the compound arguments specify what to write.
%
%   @arg PWM is a compound term of   the  form Chip(Chan), where Chan is
%   the name of  the  file  in  the   sysfs  virtual  file  system  that
%   corresponds to the exported PWM channel, which  is of the form pwmN,
%   where N is the number of the PWM channel.
%
%   @arg Term is a Prolog term that   specifies  the file to write, with
%   the name of the file as the functor   and  the value to write to the
%   file as the first argument. The   second argument, if any, specifies
%   the unit of the value (e.g., ns, s, hz, percent, fract).

sysfs_pwm_write(PWM, Term) :-
    sysfs_pwm(Chip, Export, PWM),
    sysfs_pwm_write(Chip, Export, Term).
