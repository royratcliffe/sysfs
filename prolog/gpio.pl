/*  File:    sysfs/gpio.pl
    Author:  ,,,
    Created: Dec  9 2024
    Purpose:
*/

:- module(sysfs_gpio,
          [ sysfs_gpiochip/1,                   % -Chip
            sysfs_gpiochip_phandle/2,
            sysfs_gpio/4,
            sysfs_gpiochip_read/2,
            sysfs_gpio_export/4,
            sysfs_gpio_ensure_exported/4,
            sysfs_gpio_unexport/4,
            sysfs_gpio_exported/4
          ]).
:- use_module(io).

%!  sysfs_gpiochip(-Chip) is nondet.
%!  sysfs_gpiochip(+Chip) is semidet.
%
%   Non-deterministically unifies with the GPIO  chip directories: every
%   =|gpiochip*|= directory that can be found   in  the operating system
%   under =|/sys/class/gpio|= within the =sysfs= pseudo-file system.
%
%   Use the predicate to discover all   the currently available chips or
%   use it to validate a chip.
%
%   ~~~{.pl}
%   ?- sysfs_gpiochip(A).
%   A = '/sys/class/gpio/gpiochip512' ;
%   A = '/sys/class/gpio/gpiochip570' ;
%   A = '/sys/class/gpio/gpiochip578'.
%
%   ?- sysfs_gpiochip('/sys/class/gpio/gpiochip512').
%   true ;
%   false.
%   ~~~

sysfs_gpiochip(Chip) :- sysfs_chip(gpio, Chip).

%!  sysfs_gpiochip_read(?File, ?Chip, ?Data) is nondet.
%
%   Within each GPIO chip directory, the kernel supplies
%
%   -   a base GPIO line,
%   -   a label for the chip, and
%   -   a number of GPIO lines.
%
%   Use as follows to find a specific chip by its label. The predicate
%   operates by non-deterministically iterating all the available chips
%   until it finds a match.
%
%       ?- sysfs_gpiochip_read(label, A, 'pinctrl-bcm2711').
%       A = '/sys/class/gpio/gpiochip512'.

sysfs_gpiochip_read(File, Chip, Data) :-
    gpiochip_file_type(File, Type),
    sysfs_gpiochip(Chip),
    sysfs_read(Type, Chip/File, Data).

gpiochip_file_type(base, number).
gpiochip_file_type(label, atom).
gpiochip_file_type(ngpio, number).
gpiochip_file_type(device/of_node/phandle, big(32)).

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Unify with a GPIO chip Term where the given Prolog term's functor
defines the file to read. This is mainly useful for simple files located
within the chip directory.

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

sysfs_gpiochip_read(Chip, Term) :-
    Term =.. [File, Data],
    sysfs_gpiochip_read(File, Chip, Data).

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

sysfs_gpiochip_phandle(Chip, PHandle) :-
    sysfs_gpiochip(Chip),
    sysfs_read(big(32), Chip/device/of_node/phandle, PHandle).

%!   sysfs_gpio(?Chip, ?Offset, ?Export, ?Line) is nondet.
%!   sysfs_gpio(?Chip, ?Offset, ?Line) is nondet.
%
%   Finds  all  the  GPIO  lines  for  a   Chip.  The  kernel  does  not
%   automatically export each  Line  argument.   Unifies  Line  with the
%   pre-exported Line path if it does  not   yet  exist. Exporting it to
%   userland makes the path appear.

sysfs_gpio(Chip, Offset, Export, Line) :-
    sysfs_gpiochip_read(base, Chip, Base),
    sysfs_gpiochip_read(ngpio, Chip, N),
    succ(N0, N),
    between(0, N0, Offset),
    Export is Base + Offset,
    format(atom(Line0), 'gpio~d', [Export]),
    absolute_file_name(sysfs_class(gpio/Line0), Line).

sysfs_gpiochip_of_gpio(Chip, Line) :-
    directory_file_path(Chip, _, Line).

%!  sysfs_gpio_export(?Chip, ?Offset, ?Line) is nondet.
%!  sysfs_gpio_export(?Chip, ?Line) is nondet.
%
%   Exports a Line using  its  Offset.   This  assumes  that  the Offset
%   remains constant.

sysfs_gpio_export(Chip, Offset, Export, Line) :-
    sysfs_gpio(Chip, Offset, Export, Line),
    sysfs_write(sysfs_class(gpio), export(Export)).

sysfs_gpio_exported(Chip, Offset, Export, GPIO) :-
    sysfs_gpio(Chip, Offset, Export, GPIO),
    exists_directory(GPIO).

sysfs_gpio_ensure_exported(Chip, Offset, Export, GPIO) :-
    sysfs_gpio(Chip, Offset, Export, GPIO),
    (   sysfs_gpio_exported(Chip, Offset, Export, GPIO)
    ->  true
    ;   sysfs_gpio_export(Chip, Offset, Export, GPIO)
    ).

sysfs_gpio_unexport(Chip, Offset, Export, Line) :-
    sysfs_gpio(Chip, Offset, Export, Line),
    sysfs_write(sysfs_class(gpio), unexport(Export)).

%!  sysfs_gpio_read(+Line, ?Term) is semidet.
%
%   ~~~{.pl}
%   sysfs_gpio_read(Line, value(Value)).
%   ~~~

sysfs_gpio_read(Line, Term) :-
    Term =.. [File, Data],
    sysfs_read(Line/File, Data).

sysfs_gpio_write(Line, Term) :-
    Term =.. [File, Data],
    sysfs_write(Line/File, Data).
