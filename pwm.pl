/*  File:    pwm.pl
    Author:  ,,,
    Created: Dec 10 2024
    Purpose:
*/

:- module(sysfs_pwm,
          [ sysfs_pwmchip/1,
            sysfs_pwmchip_read/3,
            sysfs_pwm/3,
            sysfs_pwm_export/3,
            sysfs_pwm_write/2,
            sysfs_pwm_read/2,
            sysfs_pwm_ensure_exported/3,
            sysfs_pwm_exported/3,
            sysfs_pwm_unexport/3
          ]).
:- use_module(io).

sysfs_pwmchip(Chip) :- sysfs_chip(pwm, Chip).

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

?- sysfs_pwmchip_read(A, B, C).
A = npwm,
B = '/sys/class/pwm/pwmchip0',
C = 1 ;
A = npwm,
B = '/sys/class/pwm/pwmchip1',
C = 1 ;
A = npwm,
B = '/sys/class/pwm/pwmchip2',
C = 17 ;
A = device/of_node/gpios,
B = '/sys/class/pwm/pwmchip0',
C = [7, 17, 0] ;
A = device/of_node/gpios,
B = '/sys/class/pwm/pwmchip1',
C = [7, 4, 0] ;
false.

Not all PWM chips have a device name. For instance, the =pwm-gpio=
driver does not publish a device name; presumably because there is no
hardware device, apart from the high-resolution timers.

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

sysfs_pwmchip_read(File, Chip, Data) :-
    file_type(File, Type),
    sysfs_pwmchip(Chip),
    sysfs_read(Type, Chip/File, Data).

file_type(npwm, number).
file_type(device/name, atom).
file_type(device/of_node/gpios, big(32)).

sysfs_pwm(Chip, Export, PWM) :-
    sysfs_pwmchip_read(npwm, Chip, N),
    succ(N0, N),
    between(0, N0, Export),
    format(atom(PWM0), 'pwm~d', [Export]),
    absolute_file_name(Chip/PWM0, PWM).

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sysfs_pwm(Chip, PWM) :- sysfs_pwm(Chip, _, PWM).

sysfs_pwm(PWM) :- sysfs_pwm(_, PWM).

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

sysfs_pwm_export(Chip, Export, PWM) :-
    sysfs_pwm(Chip, Export, PWM),
    sysfs_write(Chip, export(Export)).

sysfs_pwm_exported(Chip, Export, PWM) :-
    sysfs_pwm(Chip, Export, PWM),
    exists_directory(PWM).

sysfs_pwm_ensure_exported(Chip, Export, Chan) :-
    sysfs_pwm(Chip, Export, Chan),
    (   sysfs_pwm_exported(Chip, Export, Chan)
    ->  true
    ;   sysfs_pwm_export(Chip, Export, Chan)
    ).

sysfs_pwm_unexport(Chip, Export, PWM) :-
    sysfs_pwm(Chip, Export, PWM),
    sysfs_write(Chip, unexport(Export)).

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sysfs_pwm_unexport(Chip, PWM) :- sysfs_pwm_unexport(Chip, _, PWM).

sysfs_pwm_unexport(PWM) :- sysfs_pwm_unexport(_, PWM).

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Does it make sense to read the duty cycle as Hertz?

sysfs_pwm_read(PWM, period(NS, ns)) :-
    sysfs_read(PWM, period(NS)).
sysfs_pwm_read(PWM, period(S, s)) :-
    sysfs_pwm_read(PWM, period(NS, ns)), s(NS, S).
sysfs_pwm_read(PWM, period(Hz, hz)) :-
    sysfs_pwm_read(PWM, period(NS, ns)), hz(NS, Hz).
sysfs_pwm_read(PWM, duty_cycle(NS, ns)) :-
    sysfs_read(PWM, duty_cycle(NS)).
sysfs_pwm_read(PWM, duty_cycle(S, s)) :-
    sysfs_pwm_read(PWM, duty_cycle(NS, ns)), s(NS, S).
sysfs_pwm_read(PWM, duty_cycle(Hz, hz)) :-
    sysfs_pwm_read(PWM, duty_cycle(NS, ns)), hz(NS, Hz).

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

sysfs_pwm_read(PWM, Term) :- read_pwm(Term, PWM).

read_pwm(enable(Enable), PWM) :- sysfs_read(PWM, enable(Enable)).
read_pwm(polarity(Polarity), PWM) :- sysfs_read(PWM, polarity(Polarity)).
read_pwm(period(NS, ns), PWM) :- sysfs_read(PWM, period(NS)).
read_pwm(period(S, s), PWM) :-
    read_pwm(period(NS, ns), PWM), s(NS, S).
read_pwm(period(Hz, hz), PWM) :-
    read_pwm(period(NS, ns), PWM), hz(NS, Hz).
read_pwm(duty_cycle(NS, ns), PWM) :- sysfs_read(PWM, duty_cycle(NS)).
read_pwm(duty_cycle(S, s), PWM) :-
    read_pwm(duty_cycle(NS, ns), PWM), s(NS, S).
read_pwm(duty_cycle(Hz, hz), PWM) :-
    read_pwm(duty_cycle(NS, ns), PWM), hz(NS, Hz).
read_pwm(duty_cycle(Fract, fract), PWM) :-
    read_pwm(period(Period, ns), PWM),
    read_pwm(duty_cycle(DutyCycle, ns), PWM),
    Fract is DutyCycle / Period.
read_pwm(duty_cycle(Percent, percent), PWM) :-
    read_pwm(duty_cycle(Fract, fract), PWM),
    Percent is 100 * Fract.

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Write the period *before* the duty cycle, even if disabled. The driver
does not typically allow for the reverse.

Writing a fractional or percentage duty cycle causes a PWM read of the
period.

If the period changes, does the duty cycle also change? It *must* change if the
duty as a ratio must maintain.

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

sysfs_pwm_write(PWM, Term) :- write_pwm(Term, PWM).

write_pwm(enable(Enable), PWM) :- sysfs_write(PWM, enable(Enable)).
write_pwm(polarity(Polarity), PWM) :- sysfs_write(PWM, polarity(Polarity)).
write_pwm(period(NS, ns), PWM) :-
    NS_ is round(NS), sysfs_write(PWM, period(NS_)).
write_pwm(period(S, s), PWM) :-
    s(NS, S), write_pwm(period(NS, ns), PWM).
write_pwm(period(Hz, hz), PWM) :-
    hz(NS, Hz), write_pwm(period(NS, ns), PWM).
write_pwm(duty_cycle(NS, ns), PWM) :-
    NS_ is round(NS), sysfs_write(PWM, duty_cycle(NS_)).
write_pwm(duty_cycle(S, s), PWM) :-
    s(NS, S), write_pwm(duty_cycle(NS, ns), PWM).
write_pwm(duty_cycle(Hz, hz), PWM) :-
    hz(NS, Hz), write_pwm(duty_cycle(NS, ns), PWM).
write_pwm(duty_cycle(Fract, fract), PWM) :-
    read_pwm(period(Period, ns), PWM),
    DutyCycle is Fract * Period,
    write_pwm(duty_cycle(DutyCycle, ns), PWM).
write_pwm(duty_cycle(Percent, percent), PWM) :-
    Fract is Percent / 100,
    write_pwm(duty_cycle(Fract, fract), PWM).

s(NS, S), var(NS) => NS is 1_000_000_000 * S.
s(NS, S) => S is NS / 1_000_000_000.

hz(NS, Hz), var(NS) => NS is 1_000_000_000 / Hz.
hz(NS, Hz) => NS > 0, Hz is 1_000_000_000 / NS.
