/*  File:    sysfs/pwmchip.pl
    Author:  Roy Ratcliffe
    Created: Dec 10 2024
    Purpose: Linux sysfs PWM Chip Access

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

:- module(sysfs_pwmchip,
          [ sysfs_pwmchip_path/2 % ?Chip, ?Path
          , sysfs_pwmchip_read/2 % +What, +Term
          , sysfs_pwmchip_read/3 % +File, +Chip, -Data
          ]).
:- use_module(library(sysfs)).
:- use_module(read_file).

/** <module> Linux sysfs PWM Chip Access
 *
 * This module provides predicates to access PWM class devices in the Linux
 * sysfs virtual file system. PWM class devices are represented as directories
 * in the /sys/class/pwm directory, and contain files that provide information
 * about the device and its capabilities. The predicates in this module allow
 * you to find the paths to PWM class devices and read the values of files in
 * their directories. The main predicates in this module are:
 *
 * - sysfs_pwmchip_path/2 finds the path to a PWM class device given its name,
 *   or finds all PWM class devices and their paths.
 * - sysfs_pwmchip_read/2 reads the value of a file in the directory of a PWM
 *   class device, given a term that specifies the device and file, and the type
 *   of value to read.
 * - sysfs_pwmchip_read/3 reads the value of a file in the directory of a PWM
 *   class device, given the file name, device name, and returns the value read
 *   from the file.
 *
 * The predicates in this module are designed to be flexible and can be used in
 * various ways to access PWM class devices and their files in the sysfs virtual
 * file system.
 *
 * Example usage:
 *
 * To find the path to a specific PWM class device:
 *
 * ?- sysfs_pwmchip_path(pwmchip0, Path).
 * Path = '/sys/class/pwm/pwmchip0'.
 *
 * To find all PWM class devices and their paths:
 * ?- sysfs_pwmchip_path(Chip, Path).
 * Chip = pwmchip0,
 * Path = '/sys/class/pwm/pwmchip0' ;
 * Chip = pwmchip1,
 * Path = '/sys/class/pwm/pwmchip1' ;
 * ...
 * To read the number of PWM channels supported by a specific device:
 * ?- sysfs_pwmchip_read(pwmchip0(npwm), number(N)).
 * N = 4.
 * To read the name of a specific device:
 * ?- sysfs_pwmchip_read(pwmchip0(device/name), atom(Name)).
 * Name = 'pwmchip0'.
 * To read the number of PWM channels supported by all devices:
 * ?- sysfs_pwmchip_read(npwm, Chip, N).
 * Chip = pwmchip0,
 * N = 4 ;
 * Chip = pwmchip1,
 * N = 2 ;
 * ...
 *
 * The predicates in this module can be used in various combinations to access
 * and read information from PWM class devices in the Linux sysfs virtual file
 * system, making it easier to work with these devices in Prolog.
 *
 * @author Roy Ratcliffe
 * @version 1.0
 * @license MIT
 */

%!  sysfs_pwmchip_path(-Chip, -Path) is nondet.
%!  sysfs_pwmchip_path(+Chip, -Path) is semidet.
%
%   Finds a Chip that is a PWM class device. A Chip is a directory in the
%   /sys/class/pwm directory that contains a file named npwm, which specifies
%   the number of PWM channels that the chip supports. The Chip is returned as
%   an atom.
%
%   In the first form, the predicate is nondeterministic and can be backtracked
%   to find all PWM class devices. In the second form, the predicate is
%   deterministic and succeeds if the specified Chip is a PWM class device, and
%   fails otherwise.
%
%   @arg Chip is the name of a PWM class device, which is a directory in the
%   /sys/class/pwm directory that contains a file named npwm.
%
%   @arg Path is the absolute path to the Chip directory in the sysfs virtual
%   file system. This is returned as an atom. The absolute path is the directory
%   in the sysfs virtual file system that corresponds to the Chip, and is
%   typically of the form /sys/class/pwm/pwmchipN, where N is a number that
%   identifies the chip.

% Tempting to tableise this predicate, but it is not worth the overhead of
% tabling, as there are typically only a few PWM class devices in a system, and
% the predicate is not called frequently enough to benefit from tabling. Chips
% may also be added or removed from the system at runtime, so tabling could lead
% to stale data if a Chip is added or removed after the predicate is tabled.
sysfs_pwmchip_path(Chip, Path) :-
    sysfs_entry(pwm, Entry, [Chip, npwm]),
    (   var(Path)
    ->  file_directory_name(Entry, Path)
    ;   file_directory_name(Entry, Path),
        !
    ).

%!  sysfs_pwmchip_read(+What, +Term) is nondet.
%
%   Reads the value of a file in the Chip directory of a PWM class device. The
%   What is a term of the form Chip(File), where Chip is the name of a PWM class
%   device, and File is the name of a file in the Chip directory. The Term is
%   the type and value to read from the file.
%
%   For example, if What is pwmchip0(npwm) and Term is number(N), then it reads
%   the value of the npwm file in the pwmchip0 directory, and returns it as a
%   number N. If What is pwmchip1(device/name) and Term is atom(Name), then it
%   reads the value of the name file in the device subdirectory of the pwmchip1
%   directory, and returns it as an atom.
%
%   @arg What is a term of the form Chip(File), where Chip is the name of a PWM
%   class device, and File is the name of a file in the Chip directory.
%
%   @arg Term is a Prolog term that specifies how to read the file, as described
%   in the read_file_as/2 predicate.

sysfs_pwmchip_read(What, Term) :-
    What =.. [Chip, File],
    sysfs_pwmchip_path(Chip, Path),
    read_file_as(Path/File, Term).

%!  sysfs_pwmchip_read(+File, +Chip, -Data) is nondet.
%
%   Reads the value of a file in the Chip directory of a PWM class device. The
%   File is the name of a file in the Chip directory, such as =npwm= or
%   =device/name=. The Chip is the name of a PWM class device, such as =pwmchip0= or
%   =pwmchip1=. The Data is the value read from the file, and is returned as an
%   atom or a number depending on the type of the file. The predicate is
%   nondeterministic and can be backtracked to read the values of the same file
%   in multiple PWM class devices, or to read the values of multiple files in
%   the same PWM class device.
%
%   @arg File is the name of a file in the Chip directory, such as =npwm= or
%   =device/name=.
%
%   @arg Chip is the name of a PWM class device, such as =pwmchip0= or =pwmchip1=.
%
%   @arg Data is the value read from the file, and is returned as an atom or a
%   number depending on the type of the file.

sysfs_pwmchip_read(File, Chip, Data) :-
    file_as(File, As),
    sysfs_pwmchip_path(Chip, Path),
    read_file_as(As, Path/File, Data).

file_as(npwm, number).
file_as(device/name, atom).
file_as(device/of_node/gpios, gpios).

:- multifile sysfs_read_file:as/3.

% Read the gpios file as a list of gpio(PHandle, GPIOOffset, Flags) terms. The
% gpios file contains a sequence of big-endian 32-bit integers, where each group
% of three integers represents a GPIO line used for PWM control. The first
% integer is the phandle of the GPIO chip, the second integer is the offset of
% the GPIO line, and the third integer is a set of flags that may be specified
% in the device tree for the GPIO line. The gpios predicate converts the list of
% big-endian integers into a list of gpio/3 terms that represent the GPIO lines
% used for PWM control.
%
% For each group of three integers in the gpios file, the predicate creates a
% gpio(PHandle, GPIOOffset, Flags) term, where:
%
% @arg PHandle is the GPIO chip's phandle, which is a unique identifier for the
% chip. This is used to match the GPIO chip with the PWM chip that references it
% in its device tree node.
%
% @arg GPIOOffset is the offset of the GPIO line used for PWM control. This is
% the specific GPIO line that the PWM chip uses to control the enable signal for
% the PWM output.
%
% @arg Flags are additional flags that may be specified in the device tree for
% the GPIO line. These could indicate properties such as active low, open drain, etc.
sysfs_read_file:as(gpios, File, GPIOs) :-
    sysfs_read_file:as(bigs(32), File, Bigs),
    gpios(Bigs, GPIOs).

gpios([], []).
gpios([PHandle, GPIOOffset, Flags|Bigs], [gpio(PHandle, GPIOOffset, Flags)|GPIOs]) :- gpios(Bigs, GPIOs).
