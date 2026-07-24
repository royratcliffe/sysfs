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

gpio_line(Signal, Line) :-
    gpio_line(Signal, Label, Offset),
    gpiochip_by_label(Label, Chip),
    sysfs_gpio_line(Chip, Offset, _, Line).

forward(a) :-
    gpio_line(in(1), Line1),
    gpio_line(in(2), Line2),
    sysfs_gpio_write(Line2, value(0)),
    sysfs_gpio_write(Line1, value(1)).
forward(b) :-
    gpio_line(in(3), Line3),
    gpio_line(in(4), Line4),
    sysfs_gpio_write(Line4, value(0)),
    sysfs_gpio_write(Line3, value(1)).

reverse(a) :-
    gpio_line(in(2), Line1),
    gpio_line(in(1), Line2),
    sysfs_gpio_write(Line2, value(0)),
    sysfs_gpio_write(Line1, value(1)).
reverse(b) :-
    gpio_line(in(4), Line4),
    gpio_line(in(3), Line3),
    sysfs_gpio_write(Line4, value(0)),
    sysfs_gpio_write(Line3, value(1)).

stop(a) :-
    gpio_line(in(2), Line1),
    gpio_line(in(1), Line2),
    sysfs_gpio_write(Line2, value(0)),
    sysfs_gpio_write(Line1, value(0)).
stop(b) :-
    gpio_line(in(4), Line4),
    gpio_line(in(3), Line3),
    sysfs_gpio_write(Line4, value(0)),
    sysfs_gpio_write(Line3, value(0)).

speed(Motor, Percent/Hz) :-
    pwm(en(Motor), PWM),
    sysfs_pwm_write(PWM, period(Hz, hz)),
    sysfs_pwm_write(PWM, duty_cycle(Percent, percent)),
    sysfs_pwm_write(PWM, enable(1)).

:- end_tests(l298).
