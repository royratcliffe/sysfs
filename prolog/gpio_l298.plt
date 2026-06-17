:- begin_tests(gpio_l298).
:- use_module(gpio).
:- use_module(pwm).
:- use_module(io).

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Switch the opposite In signal first. Should it check by reading back the value?
This might be prudent.

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

forward(a) :-
    gpio(in(1), GPIO1),
    gpio(in(2), GPIO2),
    sysfs_write(GPIO2, value(0)),
    sysfs_write(GPIO1, value(1)).
forward(b) :-
    gpio(in(3), GPIO1),
    gpio(in(4), GPIO2),
    sysfs_write(GPIO2, value(0)),
    sysfs_write(GPIO1, value(1)).

reverse(a) :-
    gpio(in(2), GPIO1),
    gpio(in(1), GPIO2),
    sysfs_write(GPIO2, value(0)),
    sysfs_write(GPIO1, value(1)).
reverse(b) :-
    gpio(in(4), GPIO1),
    gpio(in(3), GPIO2),
    sysfs_write(GPIO2, value(0)),
    sysfs_write(GPIO1, value(1)).

stop(a) :-
    gpio(in(2), GPIO1),
    gpio(in(1), GPIO2),
    sysfs_write(GPIO2, value(0)),
    sysfs_write(GPIO1, value(0)).
stop(b) :-
    gpio(in(4), GPIO1),
    gpio(in(3), GPIO2),
    sysfs_write(GPIO2, value(0)),
    sysfs_write(GPIO1, value(0)).

speed(Motor, Percent/Hz) :-
    gpio_line(en(Motor), Line),
    sysfs_gpio(GPIOChip, Offset, _, Line),
    sysfs_gpiochip_offset_of_pwmchip(GPIOChip, Offset, PWMChip),
    sysfs_pwm_ensure_exported(PWMChip, 0, PWM),
    sysfs_pwm_write(PWM, period(Hz, hz)),
    sysfs_pwm_write(PWM, duty_cycle(Percent, percent)),
    sysfs_pwm_write(PWM, enable(1)).

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Finds a GPIO chip by its label. Exports the chip if not already exported.

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

gpio(Signal, GPIO) :-
    gpio_line(Signal, Label, Offset),
    exported_gpio_by_label_and_offset(Label, Offset, GPIO).

exported_gpio_by_label_and_offset(GPIOChipLabel, GPIOOffset, GPIO) :-
    sysfs_gpiochip_read(GPIOChip, label(GPIOChipLabel)),
    sysfs_gpio(GPIOChip, GPIOOffset, GPIOExport, GPIO),
    (   sysfs_gpio_exported(GPIOChip, GPIOOffset, GPIOExport, GPIO)
    ->  true
    ;   sysfs_gpio_export(GPIOChip, GPIOOffset, GPIOExport, GPIO)
    ).

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

label('pinctrl-bcm2711').

chip(Chip) :-
    label(Label),
    sysfs_gpiochip_read(label, Chip, Label).

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

gpio_line(in(1), 'pinctrl-bcm2711', 14).
gpio_line(en(a), 'pinctrl-bcm2711', 4).
gpio_line(in(2), 'pinctrl-bcm2711', 15).
gpio_line(in(3), 'pinctrl-bcm2711', 27).
gpio_line(en(b), 'pinctrl-bcm2711', 17).
gpio_line(in(4), 'pinctrl-bcm2711', 18).

sysfs_gpiochip_label(Chip, Label) :- sysfs_gpiochip_read(label, Chip, Label).

gpio_line(Signal, Line) :-
    gpio_line(Signal, Label, Offset),
    sysfs_gpiochip(Chip),
    sysfs_read(atom, Chip/label, Label),
    sysfs_gpio(Chip, Offset, _, Line).

test(gpio_line,
     [ all(A-B==
           [ 1-'/sys/class/gpio/gpio526',
             2-'/sys/class/gpio/gpio527',
             3-'/sys/class/gpio/gpio539',
             4-'/sys/class/gpio/gpio530'
           ])
     ]) :-
    gpio_line(in(A), B).

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Exporting the enable lines will fail because they have been used by the
pwm-gpio driver, making them unavailable for general GPIO access.

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

test(en_export,
     [ error(io_error(write, _),
             context(system:close/1, 'Device or resource busy'))
     ]) :-
    gpio_line(en(_), Line), sysfs_gpio_export(_, _, _, Line).

pwm_line('pwm_gpio@4', 'pinctrl-bcm2711', 4).
pwm_line('pwm_gpio@11', 'pinctrl-bcm2711', 17).

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

pwmchip_device_of_node_gpios(Chip, Bytes) :-
    sysfs_chip(pwm, Chip),
    sysfs_read(bytes, Chip/device/of_node/gpios, Bytes).

test(pwmchip_device_of_node_gpios,
     all(Chip-Bytes == [ '/sys/class/pwm/pwmchip0'-[0,0,0,7,0,0,0,17,0,0,0,0],
                         '/sys/class/pwm/pwmchip1'-[0,0,0,7,0,0,0,4,0,0,0,0]
                       ])) :-
    pwmchip_device_of_node_gpios(Chip, Bytes).
test(pwmchip_device_of_node_gpios,
     all(Chip-Words == [ '/sys/class/pwm/pwmchip0'-[7,17,0],
                         '/sys/class/pwm/pwmchip1'-[7,4,0]
                       ])) :-
    sysfs_pwmchip(Chip),
    sysfs_read(big(32), Chip/device/of_node/gpios, Words).

gpiochip_phandle(Chip, Handle) :-
    sysfs_gpiochip(Chip),
    sysfs_read(big(32), Chip/device/of_node/phandle, Handle).

test(gpiochip_phandle,
     all(Chip-Handle == [ '/sys/class/gpio/gpiochip512'-[7],
                          '/sys/class/gpio/gpiochip570'-[11],
                          '/sys/class/gpio/gpiochip578'-[254]
                        ])) :-
    gpiochip_phandle(Chip, Handle).

sysfs_gpiochip_by_label_offset_of_pwmchip(GPIOLabel, GPIOOffset, PWMChip) :-
    sysfs_gpiochip_read(label, GPIOChip, GPIOLabel),
    sysfs_gpiochip_read(device/of_node/phandle, GPIOChip, [PHandle]),
    sysfs_chip(pwm, PWMChip),
    sysfs_read(big(32), PWMChip/device/of_node/gpios, [PHandle, GPIOOffset|_]).

sysfs_gpiochip_offset_of_pwmchip(GPIOChip, GPIOOffset, PWMChip) :-
    sysfs_chip(gpio, GPIOChip),
    sysfs_read(big(32), GPIOChip/device/of_node/phandle, [PHandle]),
    sysfs_chip(pwm, PWMChip),
    sysfs_read(big(32), PWMChip/device/of_node/gpios, [PHandle, GPIOOffset|_]).

:- end_tests(gpio_l298).
