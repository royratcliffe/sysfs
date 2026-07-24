:- begin_tests(l298).
:- use_module(library(sysfs/pwmchip)).
:- use_module(library(sysfs/gpiochip)).
:- use_module(library(sysfs/pwm)).
:- use_module(library(sysfs/gpio)).
:- use_module(library(sysfs/phandles)).

:- debug(sysfs(write_file)).

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# GPIO pins 14, 15, 27 and 18 are configured as outputs and set to low by default.
# op = output, dl = default low
gpio=14,15,27,18=op,dl

# Add support for two PWM channels on GPIO 4 and GPIO 17.
# These can be used for controlling motors or other devices that require PWM signals.
dtoverlay=pwm-gpio,gpio=4
dtoverlay=pwm-gpio,gpio=17

Switch the opposite In signal first. Should it check by reading back the value?
This might be prudent.

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

pwmchip_by_label(Label, Chip) :- once(sysfs_pwmchip_read(label, Chip, Label)).

gpiochip_by_label(Label, Chip) :- once(sysfs_gpiochip_read(label, Chip, Label)).

% PWM signals for the L298 motor driver. These signals are used to
% enable the motors and control their speed via PWM.
pwm_line(en(a), 'pinctrl-bcm2711', 4).
pwm_line(en(b), 'pinctrl-bcm2711', 17).

% GPIO signals for the L298 motor driver. These signals are used to
% control the direction of the motors by setting the appropriate GPIO
% pins high or low.
gpio_line(in(1), 'pinctrl-bcm2711', 14).
gpio_line(in(2), 'pinctrl-bcm2711', 15).
gpio_line(in(3), 'pinctrl-bcm2711', 27).
gpio_line(in(4), 'pinctrl-bcm2711', 18).

:- table pwm/2, gpio_line/2.

pwm(Signal, PWM) :-
    pwm_line(Signal, Label, Offset),
    gpiochip_by_label(Label, GPIOChip),
    sysfs_gpiochip_offset_of_pwmchip(GPIOChip, Offset, PWMChip),
    % Assume that the PWM export is always channel 0 for the given GPIO pin.
    % This is a simplification and may need to be adjusted based on the actual
    % hardware configuration.
    sysfs_pwm(PWMChip, 0, PWM).

% Set the PWM period to 50 Hz for all PWM channels used in this
% configuration.
:- forall(pwm(_, PWM), sysfs_pwm_write(PWM, period(50, hz))).

gpio_line(Signal, Line) :-
    gpio_line(Signal, Label, Offset),
    gpiochip_by_label(Label, Chip),
    sysfs_gpio_line(Chip, Offset, _, Line).

% Define the forward mappings for the motors. These imply the reverse
% mappings as well, since reversing a motor simply swaps the GPIO pins
% used for forward and reverse.
ahead(port, b, 3, 4).
ahead(starboard, a, 2, 1).

% Reverse uses the same En signal but swaps the GPIO pins. For motor A,
% reverse means setting GPIO pin 2 high and GPIO pin 1 low, while for
% motor B, reverse means setting GPIO pin 4 high and GPIO pin 3 low.
astern(Abeam, En, InLo, InHi) :- ahead(Abeam, En, InHi, InLo).

bearing(ahead, Abeam, En, InHi, InLo) :- ahead(Abeam, En, InHi, InLo).
bearing(astern, Abeam, En, InHi, InLo) :- astern(Abeam, En, InHi, InLo).

bearing(ForeAft, Abeam) :-
    bearing(ForeAft, Abeam, _, InHi, InLo),
    !,
    bearing(InHi, InLo, 1, 0).
bearing(stop(slow), Abeam) :-
    !,
    bearing(ahead, Abeam, _, InHi, InLo),
    bearing(InHi, InLo, 0, 0).
bearing(stop(fast), Abeam) :-
    bearing(astern, Abeam, _, InHi, InLo),
    bearing(InHi, InLo, 1, 1).

bearing(InHi, InLo, Hi, Lo) :-
    gpio_line(in(InHi), LineHi),
    gpio_line(in(InLo), LineLo),
    % Write the low signal first to avoid stopping the motor driver.
    % Let it transition from high to low before setting the other line high.
    sysfs_gpio_write(LineLo, value(Lo)),
    sysfs_gpio_write(LineHi, value(Hi)).

throttle(Abeam, Fract) :- ahead(Abeam, En, _, _), en(En, Fract).

%! en(En, Fract) is det.
% Controls an L298 enable pin by fractional duty cycle. The En signal is associated with a specific motor (A or B), and the Fract parameter specifies the duty cycle as a fraction (0 to 1). A positive Fract value enables the motor with the specified duty cycle, while a non-positive value disables the motor.
% @arg En The enable signal for the motor (a or b).
% @arg Fract The fractional duty cycle (0 to 1) for the PWM signal controlling the motor speed. A value of 0 or less disables the motor.
en(En, Fract) :- pwm(en(En), PWM), write_en(PWM, Fract).

write_en(PWM, Fract), Fract > 0 =>
    sysfs_pwm_write(PWM, duty_cycle(Fract, fract)),
    sysfs_pwm_write(PWM, enable(1)).
write_en(PWM, Fract), Fract =< 0 =>
    % Assume that disabling the PWM signal lowers the Enable pin, effectively stopping the motor regardless of its Input pins.
    sysfs_pwm_write(PWM, enable(0)).

%! steer(Abeam, Fract) is det.
%
% Steering combines throttle and bearing to control the direction and speed of the motors. The steer predicate takes an Abeam (port or starboard) and a Fract value, which determines the throttle level and direction of the motor. If Fract is positive, it steers ahead; if negative, it steers astern.
%
% @arg Abeam The side of the vehicle (port or starboard) to steer.
% @arg Fract The fractional throttle value, where positive values indicate forward motion and negative values indicate reverse motion. The value is clamped to a minimum of 0.1 for forward and a maximum of -0.1 for reverse to prevent stalling or abrupt stops.
steer(Abeam, Fract) :-
    throttle(Abeam, 0),
    steer(Fract, ForeAft, Fract1),
    throttle(Abeam, Fract1),
    bearing(ForeAft, Abeam).

steer(Fract, ahead, Fract) :- Fract >= 0.1, !.
steer(Fract, astern, -Fract) :- Fract =< -0.1, !.
steer(_, stop(slow), 0).

:- end_tests(l298).
