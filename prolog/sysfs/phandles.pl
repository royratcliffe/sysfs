/*  File:    sysfs/phandles.pl
    Author:  Roy Ratcliffe
    Created: Dec 10 2024
    Purpose: Linux sysfs phandles for GPIO and PWM chips

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

:- module(sysfs_phandles,
          [ sysfs_gpiochip_offset_of_pwmchip/3 % ?GPIOChip, ?GPIOOffset, ?PWMChip
          ]).
:- use_module(library(sysfs/gpiochip)).
:- use_module(library(sysfs/pwmchip)).
:- use_module(library(sysfs/read_file)).
:- use_module(library(sysfs/gpio), []). % for sysfs_class_gpio file search path
:- use_module(library(sysfs/pwm), []). % for sysfs_class_pwm file search path

/** <module> Linux sysfs phandles for GPIO and PWM chips
 *
 * This module provides predicates to access   phandles for GPIO and PWM
 * chips in the Linux sysfs  virtual   file  system. Phandles are unique
 * identifiers for devices in the device tree  and are used to establish
 * relationships between devices. The predicates   in  this module allow
 * you to find the GPIO chip and offset   that correspond to a given PWM
 * chip, which is necessary for  controlling   the  PWM output using the
 * GPIO line. The main predicate in this module is:
 *
 * - sysfs_gpiochip_offset_of_pwmchip/3 finds the GPIO   chip and offset
 * that correspond to a  PWM  chip.  The   GPIO  chip  is  the chip that
 * provides the GPIO line used for PWM   control,  and the offset is the
 * specific GPIO line used for PWM  control.   The  PWM chip is the chip
 * that uses the GPIO line to control   the PWM output. The predicate is
 * nondeterministic and can be backtracked to   find  all GPIO chips and
 * offsets that correspond to PWM chips in the system.
 *
 * @author Roy Ratcliffe
 * @version 1.0
 * @license MIT
 */

% Tableise the phandle lookup for GPIO chips and PWM chips. This allows
% us to efficiently find the GPIO chip and offset that correspond to a
% given PWM chip, which is necessary for controlling the PWM output
% using the GPIO line. Tableising this predicate avoids redundant
% lookups and improves performance when working with GPIO and PWM chip
% phandles. This assumes that the phandle relationships between GPIO
% chips and PWM chips do not change at runtime, which is typically the
% case in a static hardware configuration.
:- table sysfs_gpiochip_offset_of_pwmchip/3.

%!  sysfs_gpiochip_offset_of_pwmchip(?GPIOChip, ?GPIOOffset, ?PWMChip) is nondet.
%
%   Finds the GPIO chip and offset that   correspond  to a PWM chip. The
%   GPIO chip is the chip  that  provides   the  GPIO  line used for PWM
%   control, and the offset is  the  specific   GPIO  line  used for PWM
%   control. The PWM chip is the chip that uses the GPIO line to control
%   the PWM output.  The  predicate  is   nondeterministic  and  can  be
%   backtracked to find all GPIO chips   and  offsets that correspond to
%   PWM chips in the system.
%
%   The predicate works by first finding all   GPIO  chips in the system
%   and reading their phandles. Then, it  finds   all  PWM  chips in the
%   system and reads their `gpios` file to  find the GPIO lines they use
%   for PWM control. By matching the phandle   of the GPIO chip with the
%   phandle in the `gpios` file of the  PWM chip, it can determine which
%   GPIO chip and offset correspond to which PWM chip.
%
%   @arg GPIOChip is the  name  of  a   GPIO  chip,  such  as gpiochip0,
%   gpiochip1, etc. This is the chip that   provides  the GPIO line used
%   for PWM control.
%
%   @arg GPIOOffset is the offset of the GPIO line used for PWM control.
%   This is the specific GPIO line that the PWM chip uses to control the
%   enable signal for the PWM output.
%
%   @arg PWMChip is the name of a  PWM chip, such as pwmchip0, pwmchip1,
%   etc. This is the chip that uses  the   GPIO  line to control the PWM
%   output.

sysfs_gpiochip_offset_of_pwmchip(GPIOChip, GPIOOffset, PWMChip) :-
    sysfs_gpiochip_path(GPIOChip, _),
    read_file_as(big(32), sysfs_class_gpio(GPIOChip/device/of_node/phandle), PHandle),
    sysfs_pwmchip_path(PWMChip, _),
    read_file_as(gpios, sysfs_class_pwm(PWMChip/device/of_node/gpios), [gpio(PHandle, GPIOOffset, _)|_]).
