/*  File:    sysfs_gpiochip.pl
    Author:  Roy Ratcliffe
    Created: Dec  9 2024
    Purpose: GPIO Chip Access in sysfs

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

:- module(sysfs_gpiochip,
          [ sysfs_gpiochip_path/2 % ?Chip, ?Path
          , sysfs_gpiochip_read/2 % +What:compound, +Term:compound
          , sysfs_gpiochip_read/3 % ?File, ?Chip, -Data
          ]).
:- use_module(library(sysfs)).
:- use_module(library(sysfs/read_file)).

/** <module> GPIO Chip Access in sysfs
 *
 * This module provides predicates to access GPIO chip information in
 * the sysfs file system. It allows developers to find the path to the GPIO
 * chip directory and read values from files in the GPIO chip directory,
 * such as `base`, `ngpio`, `label`, etc. The predicates are designed to be
 * flexible and can be used in various ways to access GPIO chip
 * information.
 *
 * ---+++ Usage
 *
 * Suppose you want to read the labels of _all_ the GPIO chips in sysfs.
 * You can use the predicate sysfs_gpiochip_read/3 to do so. The second
 * argument resolves non-deterministically to the name of each GPIO
 * chip, and the third argument unifies with the label read from the
 * label file in the GPIO chip directory. For example:
 *
 * ```prolog
 * sysfs_gpiochip_read(label, A, B).
 * A = gpiochip570,
 * B = 'raspberrypi-exp-gpio' ;
 * A = gpiochip512,
 * B = 'pinctrl-bcm2711' ;
 * A = gpiochip578,
 * B = '1-0040'.
 * ```
 *
 * @author Roy Ratcliffe
 * @version 1.0
 * @license MIT
 */

%!  sysfs_gpiochip_path(?Chip, ?Path) is nondet.
%
%   Finds the path to the GPIO chip directory in sysfs for the given Chip. The
%   Chip is the name of the GPIO chip, such as gpiochip0, gpiochip1, etc. The
%   Path is the absolute path to the GPIO chip directory in sysfs, such as
%   /sys/class/gpio/gpiochip0, /sys/class/gpio/gpiochip1, etc. This is used to
%   access the files in the GPIO chip directory, such as base, ngpio, label,
%   etc.

sysfs_gpiochip_path(Chip, Path) :-
    sysfs_entry(gpio, Entry, [Chip, ngpio]),
    (   var(Path)
    ->  file_directory_name(Entry, Path)
    ;   file_directory_name(Entry, Path),
        % The file system ensures that a path to a file is unique, so if the
        % path unifies with a given ground Path, then it is the correct path. If the
        % path does not unify with the given Path, then it fails and backtracks.
        !
    ).

%!  sysfs_gpiochip_read(+What:compound, +Term:compound) is semidet.
%
%   Reads a value from a file in the GPIO chip directory. The What is a compound
%   term that specifies the file to read and the Chip. The first argument of the
%   What term is the name of the file to read, such as base, ngpio, label, etc.
%   The name of the What term is the name of the Chip, such as gpiochip0,
%   gpiochip1, etc. The Term is a compound term that specifies the value to read
%   from the file. The name of the Term describes how to interpret the value,
%   and the argument of the Term is the variable to unify with the value read
%   from the file. For example, if What is gpiochip0(base) and Term is
%   number(Base), then it reads the number value from the base file in the
%   gpiochip0 directory and unifies it with the variable Base.
%
%   @arg What is a compound term that specifies the file to read and the Chip.
%   @arg Term is a compound term that specifies the value to read from the file.

sysfs_gpiochip_read(What, Term) :-
    What =.. [Chip, File],
    sysfs_gpiochip_path(Chip, Path),
    read_file_as(Path/File, Term).

%!  sysfs_gpiochip_read(?File, ?Chip, -Data) is nondet.
%
%   Reads a value from a file in the GPIO chip directory. The File is the name
%   of the file to read, such as base, ngpio, label, etc. The Chip is the name
%   of the GPIO chip, such as gpiochip0, gpiochip1, etc. The Data is the value
%   read from the file.
%
%   @arg File is the name of the file to read, such as base, ngpio, label, etc.
%   @arg Chip is the name of the GPIO chip, such as gpiochip0, gpiochip1, etc.
%   @arg Data is the value read from the file.

sysfs_gpiochip_read(File, Chip, Data) :-
    file_as(File, As),
    sysfs_gpiochip_path(Chip, Path),
    read_file_as(As, Path/File, Data).

file_as(base, number).
file_as(label, atom).
file_as(ngpio, number).
file_as(device/of_node/phandle, big(32)).
